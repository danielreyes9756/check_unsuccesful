# How to check unsuccesful logins in CENTOS 6.10
This programas gets the user who tried to access the system failed N times since the last time this program was used and write to the file /var/log/login_unsuccesful.txt
#### We had 3 types of access:
* su command: this program returns the userName also puts marks according to the expiration of the password and account.
* ssh command: this program returns the IP.
* graphic: this program returns the quantity of times.

### Contributors
* [SaraLis98](https://github.com/SaraLis98)
* [jesuslg97](https://github.com/jesuslg97)
