
## build the blog:

# check the path.
getwd()

# serve the blog subfolder:
servr::jekyll(input = "_source", output = "_posts", script = c("Makefile", "build.R"),
            command = "jekyll build --destination ../blog_dev_mm/")

# manual hack for embedocpu: get rid of line "<script src="https://data-laborer.eu/assets/js/main.min.js"></script>" 
# because it creates a bug in the matrix

art <- readLines("../blog_dev_mm/hack/embedocputest/index.html")
art <- art[!grepl('<script src="https://data-laborer.eu/assets/js/main.min.js"></script>', art)]
cat(art, file="../blog_dev_mm/hack/embedocputest/index.html", quote = F, fill=T)
