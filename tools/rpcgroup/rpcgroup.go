/*
Example:
	var group = rpcgroup.New(5000, "app1:5000", "app2:5000")
	func init() {
		id := "0001"
		group.Call(InitializeFunction, id)
	}
	var InitializeFunction = rpcgroup.Register(func(id string) {
		StartLogger(id)
	})
*/
package rpcgroup

import (
	"sync"
)

const RPCBanner string = "rpcgroup"

type Group struct {
	connections []*Client
}

// New is a constructor of Group.
// hosts must be specified by the "host:port" form.
func New(listenPort int, hosts ...string) *Group {
	c := new(Group)
	c.connections = []*Client{}
	Listen(listenPort)

	for _, host := range hosts {
		c.connections = append(c.connections, NewClient(host))
	}
	return c
}

// GroupWithoutListen is a constructor of Group that does not listen any port.
// It groups together all the hosts.
func GroupWithoutListen(hosts ...string) *Group {
	c := new(Group)
	c.connections = []*Client{}
	for _, host := range hosts {
		c.connections = append(c.connections, NewClient(host))
	}
	return c
}


// Client returns the id'th client (0-indexed)
func (c *Group) Client(id int) *Client {
	return c.connections[id]
}

func (c *Group) Call(f interface{}, params ...interface{}) [][]interface{} {
	name := GetFunctionNameOrString(f)
	return c.call(name, params...)
}

func (c *Group) call(name string, params ...interface{}) [][]interface{} {
	var wg sync.WaitGroup
	var results = make([][]interface{}, len(c.connections))
	for id, client := range c.connections {
		wg.Add(1)
		go func(id int, client *Client) {
			results[id] = client.Call(name, params...)
			wg.Done()
		}(id, client)
	}
	wg.Wait()
	return results
}
