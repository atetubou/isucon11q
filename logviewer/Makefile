.PHONY: install restart clean

logviewer: *.go
	go build -o logviewer

install: logviewer
	sudo cp logviewer /usr/bin/logviewer
	sudo cp -sf ${PWD}/logviewer.service /etc/systemd/system/
	sudo systemctl enable --now logviewer.service
	sudo systemctl restart logviewer.service
	sudo apt install colorized-logs
	mkdir ~/log
	cp -sf ../tools/Makefile /etc/systemd/system/


restart:
	sudo systemctl restart logviewer.service

clean:
	rm -rf logviewer
