# What's this about?
Cliff is a CLI-Client for [friendpaste.com][fp]. You can paste stuff to Friendpaste by piping it to cliff or fetch contents of a existing paste. It's not yet finished but should work fine. Currently only getting existing and creating new snippets is supported. Updates, Diffs, Versioning, etc. will soon follow!

And btw: [friendpaste.com][fp] is powered by [CouchDB][couch] :)

# Usage

    cliff [--help | --list-languages | --refresh]

`--help` should be pretty self-explanatory. `--list-languages` prints a list of all available languages for syntax highlighting from friendpaste. `--refresh` fetches a new list from friendpaste.com and stores it in `$HOME/.friendpaste_languages`.

    cliff [FILE] [LANGUAGE]
    cliff [SOME_EXISTING_SNIPPET_ID]

Upload stuff from stdin

    echo "Hello world!" | cliff

Upload contents from file

    cliff < file.txt
    cliff myrubyscript.rb rb

Fetch a paste

    cliff SOME_SNIPPET_ID > output.txt

# Notes
When creating a new snippet, the complete URL is copied to your clipboard for direct usage on IRC and co.

This CLI-Tool is heavily inspired by http://github.com/defunkt/gist.


[fp]: http://friendpaste.com/
[couch]: http://couchdb.apache.org/