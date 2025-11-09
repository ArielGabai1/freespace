# freespace

Recursively frees disk space by compressing files and removing old `fc-*` archives.

## Usage
`freespace [-r] [-t ###] file [file ...]`

- `-r`  : recurse into subfolders
- `-t`  : threshold in hours (default: 48)

## Examples
```bash
./freespace -t 72 /var/log
./freespace -r ~/logs
