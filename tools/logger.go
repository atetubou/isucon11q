/* INSTRUCTION:
Put the following code in initialize()
	logid := GetNextLogID()
	StartLogger(logid)


It is possible to add user defined regions for trace by adding:
	defer trace.StartRegion(context.Background(), regionName).End()
For example, in order to add it to every handler of http, one can write a wrapper as follows:
	handleFunc := func(p goji.Pattern, h func(http.ResponseWriter, *http.Request)) {
		regionName := GetFunctionName(h)
		mux.HandleFunc(p, func(a http.ResponseWriter, b *http.Request) {
			defer trace.StartRegion(context.Background(), regionName).End()
			h(a, b)
		})
	}
If you are using echo, the following code works:
	func TraceMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			defer trace.StartRegion(c.Request().Context(), c.Path()).End()
			return next(c)
		}
	}
	func main() {
		e := echo.New()
		// ...
		e.Use(TraceMiddleware)
	}
*/
package main

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"runtime/pprof"
	"runtime/trace"
	"time"
)

var startLoggerToken = make(chan bool, 1)
var stopLoggerToken = make(chan bool, 1)

const LoggerBashScript = "/usr/bin/logger.sh"
const BenchmarkTime = 60
const LogFilePath = "/tmp/isucon/"

func init() {
	startLoggerToken <- true
	os.MkdirAll(LogFilePath, os.ModePerm)
}

func ExecuteCommand(bashscript string) (string, error) {
	cmd := exec.Command("/bin/bash", "-s")
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return "", err
	}
	stdin.Write([]byte(bashscript))
	stdin.Close()
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return string(stdoutStderr), err
	}
	return string(stdoutStderr), nil
}
func MustExecuteCommand(bashscript string) string {
	res, err := ExecuteCommand(bashscript)
	if err != nil {
		log.Fatalf("Error while executing %s: %s", bashscript, res)
	}
	return res
}
func GetNextLogID() string {
	res := MustExecuteCommand(LoggerBashScript + " nextid")
	return res
}

func GetFunctionName(i interface{}) string {
	return runtime.FuncForPC(reflect.ValueOf(i).Pointer()).Name()
}

func StartLogger(id string) {
	// try to stop and wait until we get token
L:
	for {
		select {
		case <-startLoggerToken:
			break L
		case stopLoggerToken <- true:
		}
	}
	// clear stop token
	select {
	case <-stopLoggerToken:
	default:
	}

	// start logger
	log.Print(MustExecuteCommand(LoggerBashScript + " start " + id))
	f, err := os.Create(filepath.Join(LogFilePath, "cpu.prof"))
	if err != nil {
		panic(err)
	}
	runtime.SetMutexProfileFraction(1)
	runtime.SetBlockProfileRate(1)
	pprof.StartCPUProfile(f)
	f_trace, err := os.Create(filepath.Join(LogFilePath, "trace.prof"))
	if err != nil {
		panic(err)
	}
	trace.Start(f_trace)

	log.Println("Started logger")

	// stop logger after 60 sec or stop logger token is placed
	go func(id string) {
		terminated := false
		select {
		case <-stopLoggerToken:
			terminated = true
		case <-time.After(time.Second * BenchmarkTime):
		}

		pprof.StopCPUProfile()
		err := f.Close()
		if err != nil {
			panic(err)
		}
		// dump other profiles
		runtime.GC()
		profile_list := []string{"goroutine", "heap", "threadcreate", "block", "mutex"} // "allocs"
		for _, s := range profile_list {
			file, err := os.Create(filepath.Join(LogFilePath, s+".prof"))
			if err != nil {
				panic(err)
			}
			pprof.Lookup(s).WriteTo(file, 0)
			file.Close()
		}
		trace.Stop()
		if err := f_trace.Close(); err != nil {
			panic(err)
		}

		if terminated {
			res, err := ExecuteCommand(LoggerBashScript + " term " + id)
			log.Println(res)
			if err != nil {
				log.Println(err)
			}
		} else {
			log.Print(MustExecuteCommand(LoggerBashScript + " stop " + id))
		}
		log.Println("Stopped logger")
		startLoggerToken <- true
	}(id)
}
