# DDoS-DiscordNotificationAlert
DDoS Attack: Discord VPN Alerts

## How To use.
>[!NOTE]
> preferably use a virtual environment

Create a "dumps" folder for PCAPS run
```mkdir /root/dumps```

#### Uv venv
```bash
pip install uv
uv venv / python uv venv
```
#### Venv
```bash
python venv venv
```

```source .venv/bin/activate```

*Install the dependencies*
> [!IMPORTANT]
> pip install -r requirements.txt | uv pip install

## Running
*with the environment activated*
1. Choose which method you will run the scripts.
2. Nohup Or Service

### Nohup
> [!WARNING]
> If the server is restarted, it is necessary to initialize the script again via nohup.

```nohup bash discordalertsddos.sh &```

To find and terminate the process
```bash
sudo ps aux | grep bash
```
Output

- <sub> < processId > etc  0.0  0.0   etc  etc pts/1    S    TIME   0:00 bash discordalertsddos.sh </sub>

To see result...
`cat nohup.out`

to finish
```kill <processId>```

---
### Service
- __file name__ -> < any >.service
```service
[Unit]
Description=DDoS Attack: Discord VPN Alerts

After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root

WorkingDirectory=/root
ExecStart=/bin/bash discordalertsddos.sh

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```
> [!IMPORTANT]
__*Create the file and move it to >>*__
/etc/systemd/system/< any >.service

### Execute
- ```systemctl daemon-reload```

   ```bash
   systemctl enable <any>
   systemctl start <any>
   ```

  - And
  ```bash
  service <any> status
  ```
  ```bash
  service <any> start && service <any> status
  ```

To terminate the service process
```
sudo systemctl stop <any>.service
```
> [!TIP]
> after any change in the script it is necessary to run,
> ```systemctl daemon-reload```
---

Any bugs or improvements you have in mind, please get in touch
Thanks😊

# Imgs
![image](https://github.com/Salc-wm/DDoS-DiscordNotificationAlert/assets/150378169/1f575b92-5300-46ba-9fbd-822754d6f820)
![image](https://github.com/Salc-wm/DDoS-DiscordNotificationAlert/assets/150378169/aa684cb5-e75a-422b-a76c-230d80af7275)

