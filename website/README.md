This directory must contain the web site to be deployed to container.
It's either vanilla Wordpress install, or an existing Wordpress web site alongside the database schema.

In both case, add a VERSION file so the  ``make_env`` script can read your project's version (it will be used as a tag to the Docker image uploaded to private registry)

## Naming convention and file structure for vanilla installation

```
website/
├── make_env
├── README.md
├── VERSION
└── wordpress
```

For a new web site you can download and unpack Wordpress from Wordpress.org web site
Make sure the downloaded archive is extracted into a directory named "wordpress":

```bash
cd website
curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar xzvf wordpress.tar.gz
rm wordpress.tar.gz
```

Alternatively it's possible to clone Wordpress from its git repository:
```bash
git clone https://github.com/WordPress/WordPress.git website/wordpress
```


## Naming convention and file structure for installing existing wordpress based web site

```
website/
├── make_env
├── README.md
├── wordpress
├── VERSION
└── wordpress.sql
```

For existing web site you can retrieve from version control or copy project files directly.
Either way make sure, the web site is in a directory named "wordpress".
The database dump for the existing web site should be placed alongside the web site files and named "wordpress.sql"






