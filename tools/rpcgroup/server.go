package rpcgroup

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"net/rpc"
	"os"
	"time"
)

// Hostname returns host name or "" if there is an error
func Hostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = ""
	}
	return hostname
}

func generateUniqueID() string {
	return fmt.Sprintf("%s:%d:%s", RPCBanner, time.Now().UnixNano(), Hostname())
}

var UniqueID = generateUniqueID()

func GetUniqueID() string {
	return UniqueID
}
func init() {
	dummy := new(Dummy)
	rpc.Register(dummy)
	rpc.HandleHTTP()
	Register(GetUniqueID)
}

func Listen(listenPort int) {
	l, err := net.Listen("tcp", fmt.Sprintf(":%d", listenPort))
	if err != nil {
		log.Fatalf("failed to listen: %d\nError: %v", listenPort, err)
	}
	go http.Serve(l, nil)
}
