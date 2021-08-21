/*
Lockmap extends sync.Map by adding a lock.
ELement is the type of objects that can be stored in Lockmap.
Element has a function Load(), which typically returns a copied version of itself.

Typically, one uses https://github.com/globusdigital/deep-copy to implement the Load() function.
deep-copy --type LockStruct PACKAGENAME

Example:
	type TestStruct struct {
		name string
	}
	func (v TestStruct) Load() interface{} {
		w := v
		return w
	}
	func main() {
		l := LockMap{}
		l.Store(10, &TestStruct{
			name: "test",
		})
		l.Update(10, func(value Element) {
			val := value.(*TestStruct)
			val.name = "hoge"
		})
		res, ok := l.Load(10)
		if !ok {
			log.Fatal("Not found")
		}
		log.Println(res.(TestStruct).name)
	}
*/
package lockmap

import (
	"sync"
)

type LockStruct struct {
	sync.RWMutex
	value Element
}

type LockMap struct {
	sync.Map
}

// Element is the type of elements that can be stored in LockMap
type Element interface {
	// A typical usage of Load is to return a copy of itself.
	Load() interface{}
}

func (lm *LockMap) Update(key interface{}, f func(value Element)) bool {
	u, ok := lm.Map.Load(key)
	if !ok {
		return false
	}
	ls := u.(*LockStruct)
	ls.Lock()
	defer ls.Unlock()
	f(ls.value)
	return true
}

func (lm *LockMap) Store(key interface{}, value Element) {
	lm.Map.Store(key, &LockStruct{
		RWMutex: sync.RWMutex{},
		value:   value,
	})
}

func (lm *LockMap) Load(key interface{}) (interface{}, bool) {
	u, ok := lm.Map.Load(key)
	if !ok {
		return nil, false
	}
	ls := u.(*LockStruct)
	ls.RLock()
	defer ls.RUnlock()
	return ls.value.Load(), true
}
