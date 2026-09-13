# Apache virtual-host lab tools

Bash scripts for creating, listing, suspending, resuming and deleting HTTPS virtual hosts on a RHEL-style Apache installation (`httpd`).

## Requirements

Linux, Bash, OpenSSL supporting `-addext`, Apache with mod_ssl, and systemd. Configure Apache to listen on port 443 and include `/etc/httpd/conf.d/vhosts/*.conf`. The scripts use `/var/www` for content and `/etc/httpd/conf.d/certificate` for certificates. Review those paths in `common.sh` before use. Mutating scripts require root; run one operation at a time.

```sh
sudo bash createvhost.sh app.example.com 192.0.2.10
bash listall.sh
bash listavailablevhosts.sh
sudo bash suspenedvhost.sh app.example.com
bash listsuspenedvhosts.sh
sudo bash resumevhost.sh app.example.com
sudo bash deletevhost.sh app.example.com
```

Replace the example IP with an address actually assigned to your server. Configure DNS or a client hosts-file entry yourself. Creation refuses existing content or certificate paths and generates a self-signed lab certificate. Use a trusted certificate for real hosting.

Deletion retains website content by default. Add `--delete-content` only when you intend to permanently delete the site's document root. The legacy `dellhostdir` argument remains accepted. Logs and hosts-file entries are retained for manual review.

Configuration changes run `apachectl configtest` and reload Apache; failed changes restore the previous configuration. Run on a disposable host first. These scripts do not manage DNS, firewall policy, SELinux labels, certificate renewal, or concurrent administration. The original misspelled script names are preserved for compatibility.
