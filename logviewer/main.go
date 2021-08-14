package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/exec"
	"regexp"
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
		//if path.Ext(upath) == ".prof" {
		base := string(res[1])
		//log.Println("profile: " + upath)
		//log.Println("matched: ", string(res[0]), string(res[1]), string(res[2]))
		listeners.Lock()
		port, ok := listeners.path2port[base]
		if !ok {
			testListener, err := net.Listen("tcp", "127.0.0.1:0")
			if err != nil {
				panic(err)
			}
			port = testListener.Addr().(*net.TCPAddr).Port
			if err := testListener.Close(); err != nil {
				panic(err)
			}
			log.Println("Port:", port)
			Exec(fmt.Sprintf("go tool pprof -http localhost:%d -no_browser %s%s", port, h.root, base))
			listeners.path2port[base] = port
			listeners.Unlock()
			time.Sleep(time.Second * 1)
		} else {
			listeners.Unlock()
		}
		//if string(res[2]) == "" || string(res[2]) == "/" {
		//	r.URL.Path = "/ui/"
		//} else {
		//	r.URL.Path = string(res[2])
		//}
		r.URL.Path = string(res[2])
		u, err := url.Parse(fmt.Sprintf("http://localhost:%d/", port))
		if err != nil {
			log.Fatal(err)
		}
		proxy := httputil.NewSingleHostReverseProxy(u)
		proxy.ModifyResponse = func(res *http.Response) error {
			// Change forwarding
			//log.Println(res)
			uri, err := res.Location()
			if err == nil {
				s := base + uri.Path
				//log.Println(s)
				res.Header.Set("Location", s)
			}
			return nil
		}
		proxy.ServeHTTP(w, r)
		/*
			director := func(request *http.Request) {
				request.URL.Scheme = "http"
				request.URL.Host = "localhost:9000"
			}
			proxy := httputil.ReverseProxy{Director: director}
			proxy.ServeHTTP(w, r)
		*/
		return
	} else {
		http.ServeFile(w, r, filepath)
	}
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
	port := *flag.String("p", "8080", "port to serve on")
	root := *flag.String("d", ".", "the directory of static file to host")
	flag.Parse()

	http.Handle("/", LogHandler{root})
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
