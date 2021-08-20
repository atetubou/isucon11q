package lockmap

import (
	"log"
	"testing"
)

type TestStruct struct {
	name string
}

func (v *TestStruct) Load() interface{} {
	/*
		var w TestStruct
		w = *v
	*/
	w := *v
	log.Println(&w != v)
	return w
}

func TestLockMap(t *testing.T) {
	l := LockMap{}
	l.Store(10, &TestStruct{
		name: "test",
	})
	l.Update(10, func(value interface{}) {
		val := (value).(*TestStruct)
		val.name = "hoge"
	})
	log.Println("OK")
	a, ok := l.Load(10)
	if !ok {
		log.Fatal("Not found")
	}
	log.Println("OK")
	if a.(TestStruct).name != "hoge" {
		log.Fatal("name:", a.(TestStruct).name)
	}
	log.Println("OK")
	log.Println(a.(TestStruct))

}
