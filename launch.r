
## build the blog:

# check the path. Should be "C:/blog/gen"
getwd()

# we don't want split images
options("base64_images")


# serve the blog subfolder:
servr::jekyll(input = "_source", output = "_posts")

