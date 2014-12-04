# Album of the Day Downloader

A ruby script that downloads the Album of the Day (r/Albumoftheday) to a Deluge seedbox.

I wrote this tool to practice with APIs. I use the Reddit API to get the title of the latest Album of the Day post, I use the iTunes API to verify the album in question exists, I use a PirateBay Ruby library to get torrent data, and finally I use the deluge-webapi to start the torrent download.

# Steps to configure and run

1. Clone project
2. Install the [deluge-webapi](https://github.com/idlesign/deluge-webapi) plugin on your Deluge seedbox
3. Modify config.json to connect to your seedbox
4. run `bundle` to get dependencies
5. run `ruby main.rb`

