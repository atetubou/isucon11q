.PHONY: install restart clean

logviewer: *.go
	go build -o logviewer

install: logviewer
	sudo systemctl disable --now logviewer.service
	sudo cp logviewer /usr/bin/logviewer
	sudo cp -sf ${PWD}/logviewer.service /etc/systemd/system/
	sudo systemctl enable --now logviewer.service
	sudo systemctl restart logviewer.service
	sudo apt install colorized-logs
	sudo -u isucon bash -c 'mkdir -p ~/log'
	sudo cp -sf ${PWD}/../tools/Makefile /etc/systemd/system/


restart:
	sudo systemctl restart logviewer.service

clean:
	rm -rf logviewer
