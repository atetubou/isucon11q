logviewer: *.go
	go build -o logviewer

install:
	sudo cp -sf ${PWD}/logviewer.service /etc/systemd/system/
	sudo systemctl enable --now logviewer.service
	sudo systemctl restart logviewer.service

restart:
	sudo systemctl restart logviewer.service

clean:
	rm -rf logviewer
