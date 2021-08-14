logviewer: *.go
	go build -o logviewer

install:
	sudo cp -s ${PWD}/logviewer.service /etc/systemd/system/
	sudo systemctl enable --now logviewer.service

restart:
	sudo systemctl restart logviewer.service

clean:
	rm -rf logviewer
