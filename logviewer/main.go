package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Listeners struct {
	sync.Mutex
	path2port map[string]int
}

var listeners = Listeners{path2port: map[string]int{}}

type LogHandler struct {
	root string
}

func GetAvailablePort() int {
	testListener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		panic(err)
	}
	port := testListener.Addr().(*net.TCPAddr).Port
	if err := testListener.Close(); err != nil {
		panic(err)
	}
	return port
}

func (h LogHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	upath := r.URL.Path
	if !strings.HasPrefix(upath, "/") {
		upath = "/" + upath
		r.URL.Path = upath
	}
	filepath := h.root + upath
	re := regexp.MustCompile(`^(.*\.prof)(/?.*)`)
	res := re.FindSubmatch([]byte(upath))
	if len(res) > 0 {
		base := string(res[1])
		listeners.Lock()
		port, ok := listeners.path2port[base]
		if !ok {
			port = GetAvailablePort()
			log.Println("Port:", port)
			if strings.HasSuffix(base, "trace.prof") {
				Exec(fmt.Sprintf("go tool trace -http=:%d %s%s", port, h.root, base))
			} else {
				Exec(fmt.Sprintf("go tool pprof -http localhost:%d -no_browser %s%s", port, h.root, base))
			}
			listeners.path2port[base] = port
			listeners.Unlock()
			time.Sleep(time.Second * 1)
		} else {
			listeners.Unlock()
		}
		r.URL.Path = string(res[2])
		u, err := url.Parse(fmt.Sprintf("http://localhost:%d/", port))
		if err != nil {
			log.Fatal(err)
		}
		proxy := httputil.NewSingleHostReverseProxy(u)
		proxy.ModifyResponse = func(res *http.Response) error {
			// Change forwarding
			uri, err := res.Location()
			if err == nil {
				s := base + uri.Path
				res.Header.Set("Location", s)
			}
			if strings.HasSuffix(base, "trace.prof") {
				b, err := io.ReadAll(res.Body)
				if err != nil {
					log.Fatal(err)
				}
				payload := fmt.Sprintf(`<script type='text/javascript'>function replace_url(elem, attr) { var elems = document.getElementsByTagName(elem); for (var i = 0; i < elems.length; i++) elems[i][attr] = elems[i][attr].replace(/^http:\/\/[^\/]*\//, '%s/'); } replace_url("a", "href");</script>`, base)
				s := string(b) + payload
				b = []byte(s)
				res.Body = io.NopCloser(bytes.NewReader(b))
				res.Header.Set("Content-Length", strconv.Itoa(len(b)))
			}
			return nil
		}
		proxy.ServeHTTP(w, r)
	} else if strings.HasSuffix(filepath, "dstat.log") {
		// use aha (Ansi HTML Adapter) to display dstat
		f, err := os.Open(filepath)
		if err != nil {
			msg, code := ToHTTPError(err)
			http.Error(w, msg, code)
			return
		}
		defer f.Close()
		content, err := io.ReadAll(f)
		if err != nil {
			log.Fatal(err)
		}

		cmd := exec.Command("aha")
		stdin, err := cmd.StdinPipe()
		if err != nil {
			log.Fatal(err)
		}
		go func() {
			writer := bufio.NewWriter(stdin)
			_, err = writer.Write(content)
			if err != nil {
				log.Fatal(err)
			}
			stdin.Close()
		}()
		out, err := cmd.Output()
		if err != nil {
			log.Fatal(err)
		}
		fmt.Fprint(w, string(out))
	} else {
		http.ServeFile(w, r, filepath)
	}
}

func ToHTTPError(err error) (msg string, httpStatus int) {
	if os.IsNotExist(err) {
		return "404 page not found", http.StatusNotFound
	}
	if os.IsPermission(err) {
		return "403 Forbidden", http.StatusForbidden
	}
	// Default:
	return "500 Internal Server Error", http.StatusInternalServerError
}

func Exec(command string) {
	args := strings.Split(command, " ")
	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Start()
	if err != nil {
		log.Fatal(err)
	}
}

func main() {
	port := flag.String("p", "8080", "port to serve on")
	root := flag.String("d", ".", "the directory of static file to host")
	flag.Parse()

	http.Handle("/", LogHandler{*root})
	log.Println("Serving at port", *port)
	log.Fatal(http.ListenAndServe(":"+*port, nil))
}
