---
layout: single
title: "Send an Email to all your Representatives. With R."
categories: [hack]
tags: [R, XML]
date: 2015-07-15
excerpt: Script to scrape the website of the french senat and send 300 emails
teaser: assets/images/senat.jpg
---

I disagreed with the recent law the French government pass.

I wanted to explain my point of view to the French senators and did it manually at first. After sending two mails, it hits me that it is possible to do a script to automate it and even a R script.

The two main packages used are `XML` and `mailR`, respectively to do the HTML scraping and automatically sent mails.

The XML package is really simple to handle for this task and have the `getHTMLLinks()` function which extract all the link from a webpage.

<h1> Scrape the senate website </h1>

In the French senate website, we could find a personal page for each senator and a few information on our representatives, including the group, the mail provided by the senate and sometime personals mails.

The first step is to get all the personal web pages of the senators.


{% highlight r %}
# packages used: 
library(XML) # install.packages("XML")
library(plyr) # install.packages("plyr")
library(stringr) # install.packages("stringr")

# url of the main page of the senat website
xml.url.short <- "http://www.senat.fr" 
xml.url <- paste0(xml.url.short, "/senateurs/senatl.html")

### get all the links of the senator website:
senateur.raw.link <- getHTMLLinks(xml.url)

## cleaning the set of link:
  # we keep only the ones beginning by /senateur/:
senateur.link <- unlist(senateur.raw.link)[substr(unlist(senateur.raw.link), 1, 10) == "/senateur/"]
  # we add the full path:
senateur.full.link <- paste0(xml.url.short, senateur.link)

### now, getting every mail address from these link:
  # function to get: name, surname, mail address, group, profession, circonscription
      # based on the link
senateur.infos.primaire <- data.frame(link = senateur.full.link
                , mail = "", full.name.surname = "", group = "", stringsAsFactors = F)

# timer
ptm <- proc.time()

for (i in 1:length(senateur.full.link)) { # i <- 1
  
  # mail:
  links <- unlist(getHTMLLinks(senateur.full.link[i], externalOnly = F))
  mails <- links[substr(links, 1, 6) == "mailto"]
  mail <- substr(mails[!substr(mails, 1, 20) %in% c("mailto:notices-senat", "mailto:?subject=&bod")], 8, 200)
  senateur.infos.primaire$mail[i] <- ifelse(length(mail) != 0, mail[length(mail)], "")
  
  # name and surname:
senateur.infos.primaire$full.name.surname[i] <- substr(mails[substr(mails, 1, 20) %in% c("mailto:notices-senat")], 66, 200)
}

print(ptm0 <- ptm - proc.time())

## convert to correct encoding to deal with the special characters
senateur.infos.primaire$full.name.surname <- iconv(senateur.infos.primaire$full.name.surname, from = "UTF-8", to = "LATIN2")

# sex definition:
senateur.infos.primaire$sexe <- ifelse(substr(senateur.infos.primaire$full.name.surname, 1, 5) == "de la", "F", " ")
senateur.infos.primaire$sexe <- ifelse(substr(senateur.infos.primaire$full.name.surname, 1, 4) == "du S", "M", senateur.infos.primaire$sexe)
{% endhighlight %}




In the end, we get a file with all the emails of the French senators and the associated details.

<h1> Sending the emails </h1>

The package `mailR` allows to send email within R. It is very useful when you have really long process and you want to be averted when the process is finished.

In addition, the function `send.mail` send HTML formatted emails, which allows a great deal of customization.

To facilitate the debugging, the mail is written in HTML then the `brew` package is used to replace the names, and personalize the message looking at the group. It allows as well to keep the log of the mail.


{% highlight r %}
## rJava is needed first
library(mailR)  # install.packages("mailR", dep = T)  
library(brew)  # install.packages("brew")
# install.packages("rJava", repos = "http://cran.univ-paris1.fr/") #  options(java.home="C:\\Program Files\\Java\\jre1.8.0_45\\") # library(rJava)

for(i in 1:dim(senateur.infos.primaire)[1]) {  #i <- 1

# create the log file
brew(file = paste0(path, "/Mail Template/template mail.html"), output = paste0(path, "/Log/Mail_", i, ".html") )

# the body of the mail
body <- paste0(scan(file = paste0(path, "/Log/Mail_", i, ".html"), what = "raw", sep = "|"), collapse = "")

from <- "my@email.com"
to <- senateur.infos.primaire[i, "mail"]

tt <- send.mail(from = from, to = to
          , subject = "Loi renseignement"
          , body = body
          , html = TRUE
          , smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "my username"
                      , passwd = "my password", ssl = TRUE)
          , authenticate = TRUE
          , SEND = TRUE)
}
{% endhighlight %}

The loop for sending the email could take a few minutes.

<h1> Parity Analysis </h1>

The file allows an analysis of the parity. 




{% highlight r %}
# plot
ggplot(senateur.infos, aes(x = group, fill= sexe)) + geom_bar() +
  scale_x_discrete(name = "Group") +
  scale_y_continuous(name = "Number of senator\n") +
  scale_fill_discrete(name = "Sex") +
  ggtitle("Repartition of sex among the senators by group\n") +
  theme(axis.text.x = element_text(colour = "blue", size = 10)
        , axis.text.y = element_text(colour = "blue", size = 13)
        , panel.background = element_rect(fill = "white")
        , panel.grid.major.y = element_line(colour = "darkgrey", size = 1)
        , panel.grid.minor.y = element_line(colour = "grey", size = 0.5)
        , panel.grid.major.x = element_blank()
        , plot.title = element_text(size = 20, colour = "darkblue")
        , legend.title = element_text(size = 15, colour = "darkcyan")
        , legend.text = element_text(size = 13, colour = "blue")
        , axis.title = element_text(size = 15, colour = "darkcyan", face = "bold"))
{% endhighlight %}

![plot of chunk unnamed-chunk-5](http://yvescr.github.io/assets/images/figures/source/2015-07-15-Mail_to_senateur/unnamed-chunk-5-1.png)

Only the CRC (communists) and the ecologists have a strict parity.
