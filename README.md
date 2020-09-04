# PrettyIndex


## About

PrettyIndex is an unofficial improved User Interface (UI) of AutoIndex Module of [Apache2](https://www.apache.org/). The Apache autoindex module automatically generates web page listing the contents of directories on the server, typically used so that an index.html does not have to be generated.

<a id="installation-and-update"></a>
<a id="install-script"></a>

## Installing and Updating

### Install & Update Script

To **install** or **update** PrettyIndex, you should execute few lines of codes. To do that, you may either download and run the script manually, or use the following cURL or Wget command:

```sh
curl -o- https://raw.githubusercontent.com/webcdn/PrettyIndex/latest/install.sh | bash
```

```sh
wget -qO- https://raw.githubusercontent.com/webcdn/PrettyIndex/latest/install.sh | bash
```

Running either of the above commands downloads a script and runs it. The script clones the PrettyIndex repository from [GitHub](https://github.com/webcdn/PrettyIndex) to `/usr/lib/apache2/PrettyIndex`, and attempts to modify a few of files,  adding minified icon set with few more functioanlities like searching and more to go.

<a id="profile_snippet"></a>


## License

PrettyIndex is released under the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
