# Contrubuting to GABS:

Feel free to make pull requests, but do keep in mind GABS runs on bare metal servers that rely on it for data backups.

Make sure you can check off the following before submitting a pull request:

- [ ] Does the script run without error? Does it still have adequate logging for events that might result in an error?
- [ ] Have you ensured the script does not unintentionally remove data?
- [ ] Have you tested the script on bare metal or an equivalent virtualized setup?
- [ ] Can the script still be reliably called by an automated task such as cron?

If your pull request causes any of these to occur, your PR will be dismissed or you will be requested changes. 
