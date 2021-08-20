package rpcgroup

import (
	"log"
	"sync"
	"testing"
)

func Add(a int, b int) int {
	return a + b
}

type Counter struct {
	sync.Mutex
	value int
}

var counter Counter

func AddToCounter(value int) {
	counter.Lock()
	defer counter.Unlock()
	counter.value += value
}

var AddName = Register(Add)
var AddToCounterName = Register(AddToCounter)

var NoNameFunc = Register(func() int { return 10 })

func TestNoNameFunc(t *testing.T) {
	log.Println(NoNameFunc)
	if Call(NoNameFunc)[0].(int) != 10 {
		t.Fatal("unexpected")
	}
}

func TestCall(t *testing.T) {
	if Call(AddName, 10, 21)[0].(int) != 31 {
		t.Fatal("unexpected")
	}
}

func TestServerAndClient(t *testing.T) {
	Listen(12345)
	c := NewClient("localhost:12345")
	if c.Call(AddName, 10, 21)[0].(int) != 31 {
		t.Fatal("unexpected")
	}
}

func TestGroup(t *testing.T) {
	counter.value = 0
	group1 := New(12340, "localhost:12340", "localhost:12341")
	group2 := New(12341, "localhost:12340", "localhost:12341")
	group1.Call(AddToCounterName, 3)
	if counter.value != 6 {
		t.Fatal("unexpected")
	}
	group2.Call(AddToCounter, 10)
	if counter.value != 26 {
		t.Fatal("unexpected")
	}
}

/*
func TestError(t *testing.T) {
	Listen(12346)
	c := NewClient("localhost:12344")
	if c.Call("Add", 10, 21)[0].(int) != 31 {
		t.Fatal("unexpected")
	}
}
*/
