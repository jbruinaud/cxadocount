# cxadocount

bash script to count the LOC for each git repo in a given ADO org (projects can contain multiple repos)

Pre-requisites: git, jq, curl and cloc-1.88.pl (https://github.com/AlDanial/cloc/releases/download/1.88/cloc-1.88.pl)

Tested on Amazon EC2 linux 4.14.121-109.96.amzn2.x86_64

# Usage

First, update cxadocount.sh with your ADO org and your ADO PAT. Make sure that you have git, jq, and curl installed and that cloc-1.88.pl is present in the same directory.

<pre>
$ chmod +x ./cloc-1.88.pl
$ chmod +x ./cxadocount.sh
$ ./cxadocount.sh
</pre>

# What does the script do?

<pre>
- List the projects from the ADO org
  - For each project
    - List the repositories
    - For each repository
      - Clone the repository locally
      - Run cloc on the local clone folder
      - Add the repo LOC to the output file
      - Remove the local clone folder
</pre>

# Output example

<pre>
$ cat results.csv
Project,Repo,Languages,Count
DSVW,DSVW,Python,93
WebGoat,WebGoat,C# / ASP.NET / JavaScript / SQL / ASP,10064
</pre>
