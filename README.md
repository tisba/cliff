# What's this about?
Creating a CLI-Client for interacting with friendpaste.com

# Usage
<pre>
$ clif < file.txt
$ cat mycode.rb | clif rb # Clif will try to find a matching language for syntax hl
$ clif someexistingfile.txt # Clif will upload the contents of the file if it exists
$ clif SOME_SNIPPET_ID > output.txt
</pre>

# Notes
This CLI-Tool is heavily inspired by http://github.com/defunkt/gist.

# This is only a little experiment for me and not even half done :)