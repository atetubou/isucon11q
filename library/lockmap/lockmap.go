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

func (lm *LockMap) Update(key interface{}, f func(value interface{})) bool {
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
