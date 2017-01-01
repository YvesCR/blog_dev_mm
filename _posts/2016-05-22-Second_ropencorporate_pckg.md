---
layout: single
title: "Explore Company Officers of EDF with Ropencorporate"
categories: [hack]
tags: [R, open corporates, package]
date: 2016-05-22
excerpt: Exemple of how to use the Ropencorporate package
teaser: assets/images/logog_oc.png
---

This article follow a [first article](http://data-laborer.eu/2016/05/Presentation_of_the_Ropencorporate_package.html) on how to extract information on a specific company from the [opencorporate](http://api.opencorporates.com/) database. 

The first article was focused on companies. Now, we focus on officers.

There is multiple methods to get information on officers with the API: with the method GET officers/search, which allows to get informations on a particular officers based on a name, with the method GET officers/:id which allows to get back information based on an id and with the method GET companies/:jurisdiction_code/:comapny_number, where based on a company_number we could get the id of the officers of the company.

The function `get.officers` is a wrapper for the first method.
The second method is not reqlly interesting, as there is not a unique id per civil id, making the query useless to create links.
The third method is implemented through the function `get.comp.number`.

The question that we could answer, here, is how to find the key officers of EDF? who are the most central officers?

## Initialisation




<pre><code class="prettyprint ">library(Ropencorporate, quietly = T)
library(data.table)
library(DT)
library(stringr)
library(stringi)
library(networkD3, quietly = T, warn.conflicts = F)</code></pre>

First, we load the details of all the companies related to the term "EDF" created in the first article.


<pre><code class="prettyprint ">load(file = paste0(&quot;data/res_oc_&quot;, term, &quot;.rda&quot;)) # res.oc</code></pre>



<pre><code>## Warning in readChar(con, 5L, useBytes = TRUE): impossible d'ouvrir le
## fichier compressé 'data/res_oc_edf.rda', cause probable : 'No such file or
## directory'
</code></pre>



<pre><code>## Error in readChar(con, 5L, useBytes = TRUE): impossible d'ouvrir la connexion
</code></pre>

Then we query details of the companies, with the help of the function `get.comp.number`.


<pre><code class="prettyprint ">company.number &lt;- res.oc$oc.dt[, company.number]
jurisdiction.code &lt;- res.oc$oc.dt[, jurisdiction.code]
company.out.l &lt;- get.comp.number(company.number, jurisdiction.code)</code></pre>




<pre><code>## Warning in readChar(con, 5L, useBytes = TRUE): impossible d'ouvrir le
## fichier compressé 'data/company_result_query_id_edf.rda', cause probable :
## 'No such file or directory'
</code></pre>



<pre><code>## Error in readChar(con, 5L, useBytes = TRUE): impossible d'ouvrir la connexion
</code></pre>

The result of the function is a list with 4 data-table (or data-frame if the package `data.table` is not loaded). The first table give details of companies and the second details of officers.

Combine, they permit to create an estimation of the mapping of the interconnection between officers and companies.
The uncertainty lying on duplicates of name of society per jurisdiction code(unlikely) and duplicates of names among the societies(likely to happen). So you are warned, it is possible that a same node could be multiple persons or companies.

We are pretty confident that there is no two EDF LLC. in the UK, but we are not confident at all that there is only one Robert Miller among the officers of companies with EDF in the name.

A project here could be to create a scarcity score per name and surname. That way, a rare name appearing two times would show a high confidence of being the same person and a common name appearing a lot of time would show a low confidence of being the same person.

Some cleaning among the names could nevertheless be done. For exemple, we could get rid of the initial of the second name. In that case, we loose a bit of precision in the result.


<pre><code class="prettyprint ">officers.comp.dt &lt;- company.out.l$officers.comp.dt</code></pre>



<pre><code>## Error in eval(expr, envir, enclos): objet 'company.out.l' introuvable
</code></pre>



<pre><code class="prettyprint "># get rid of second name abreviation
officers.comp.dt[, name.clean := gsub(&quot;([ ][A-Z][/.])&quot;, &quot;&quot;, stri_trans_totitle(tolower(name)))]</code></pre>



<pre><code>## Error in eval(expr, envir, enclos): objet 'officers.comp.dt' introuvable
</code></pre>



<pre><code class="prettyprint "># Clean officers title
officers.comp.dt[, position := stri_trans_totitle(tolower(position))]</code></pre>



<pre><code>## Error in eval(expr, envir, enclos): objet 'officers.comp.dt' introuvable
</code></pre>

## Simple analysis

From a simple count, we can see that a lot of companies have, as officer, "CORPORATION SERVICE COMPANY". It is a large [Registered Agent service companies](https://en.wikipedia.org/wiki/Corporation_Service_Company) situated in the Delaware.


<pre><code class="prettyprint ">datatable(officers.comp.dt[, .N, by = c(&quot;name.clean&quot;, &quot;position&quot;)][order(N, decreasing = T)])</code></pre>



<pre><code>## Error in base::rownames(data): objet 'officers.comp.dt' introuvable
</code></pre>

For companies registered in the UK, we have the nationality of the officers. Here, we could see that companies are mainly represented by British and Frenchs officers.


<pre><code class="prettyprint ">datatable(officers.comp.dt[, .N, by = &quot;nationality&quot;][order(N, decreasing = T)])</code></pre>



<pre><code>## Error in base::rownames(data): objet 'officers.comp.dt' introuvable
</code></pre>

## Graph analysis

### R code

Now, what we want to represent is the link between officers and companies.
For that, we use the `forceNetwork` function, which allows to do a force directed network graph (logic).
Here, we consider that the same officer with multiple positions as two nodes, as we want to give a color for each position.


<pre><code class="prettyprint ">company.id.dt &lt;- company.out.l$company.id.dt

# merge both tables:
comp.officers &lt;- merge(officers.comp.dt, company.id.dt[
, list(jurisdiction.code, company.number, name.company = name)]
, by = c(&quot;jurisdiction.code&quot;, &quot;company.number&quot;))

# clear position: if less than 20 of a position, it goes into Other
comp.officers[, position2 := ifelse(.N &lt; 20, &quot;Other&quot;, position), by = &quot;position&quot;]
comp.officers[, name2 := paste0(name.clean, &quot;, &quot;, position2)]

# nodes:
nodes.c &lt;- unique(c(comp.officers[, name2], comp.officers[, name.company]))
node0 &lt;- data.frame(ID = 0:(length(nodes.c) - 1)
                    , name = nodes.c, size = 25
                    , stringsAsFactors = F)

# nodes with group: one color per position and one for company
nodes.with.group &lt;- merge(node0
      , unique(comp.officers[, list(name2
        , group = as.numeric(as.factor(name2)))])
      , by.x = &quot;name&quot;, by.y = &quot;name2&quot;, all.x = T)

# put a high value for company for the group and the size
nodes.with.group$group[is.na(nodes.with.group$group)] &lt;- 30
nodes.with.group$size[is.na(nodes.with.group$group)] &lt;- 50

# sort the table
node &lt;- nodes.with.group[order(nodes.with.group$ID), ]

# links 
links0 &lt;- merge(
  merge(
    comp.officers[!(is.na(name.clean)|is.na(name.company))
                  , list(value = .N), by = c(&quot;name2&quot;, &quot;name.company&quot;)]
    , node0, by.x = &quot;name2&quot;, by.y = &quot;name&quot;, all.x = T)
  , node0, by.x = &quot;name.company&quot;, by.y = &quot;name&quot;, all.x = T)

links &lt;- data.table(links0[, list(source = ID.x, target = ID.y
                      , value = value)])</code></pre>

### Graph of companies and offers by position 

The final result is a huge graph, of nearly 1Mb. You could find the live version [here](http://data-laborer.eu/Pages/Force_field_officers.html), but try not to open it with a smartphone or a low frequency connexion.


<pre><code class="prettyprint ">forceNetwork(Links = links, Nodes = node, Source = &quot;source&quot;,
             Target = &quot;target&quot;, Value = &quot;value&quot;, NodeID = &quot;name&quot;,
             Group = &quot;group&quot;, opacity = 1, zoom = TRUE)</code></pre>

For the article, an image is enough.
![Full force field](http://data-laborer.eu/assets/images/special/Open_corporqte_edf_officers_force_network.png)

We can see in the left a middle sized cluster where mainly American companies could be found. It is likely the North America branchs of EDF.

The main cluster is made of british companies; we could see a middle-sized cluster relied through only one man, Philippe Crouzat, financial director of EDF renewable energy. It is the renewable energy branch of EDF.

From that graph, we could identify key officers and close companies inside a conglomerate.

### Graph of companies and offers by jurisdiction

The same graph could be made based on the jurisdiction code.
So that time, we want to represent one point per officer and company, but with a different color per jurisdiction.

The code is a bit different, here:


<pre><code class="prettyprint ">comp.officers[, jurisdiction.code2 := ifelse(substring(jurisdiction.code, 1, 2) %in% c(&quot;us&quot;, &quot;ca&quot;)
                          , substring(jurisdiction.code, 1, 2), jurisdiction.code)]
comp.officers[, jurisdiction.code3 := ifelse(.N &lt; 5, &quot;Other&quot;, jurisdiction.code2), by = &quot;jurisdiction.code2&quot;]
comp.officers[, name.company2 := paste0(name.company, &quot;, &quot;, jurisdiction.code3)]

# nodes:
nodes.c &lt;- unique(c(comp.officers[, name.clean], comp.officers[, name.company2]))
node0 &lt;- data.frame(ID = 0:(length(nodes.c) - 1)
                    , name = nodes.c, size = 25
                    , stringsAsFactors = F)

# nodes with group: one color per jurisdiction and one for officers
nodes.with.group2 &lt;- merge(node0
      , unique(comp.officers[, list(name.company2 
        , group = as.numeric(as.factor(jurisdiction.code3)))])
      , by.x = &quot;name&quot;, by.y = &quot;name.company2&quot;, all.x = T)

# put a high value for officers for the group and the size
nodes.with.group2$group[is.na(nodes.with.group2$group)] &lt;- 30
nodes.with.group2$size[is.na(nodes.with.group2$group)] &lt;- 50

# sort the table
node2 &lt;- nodes.with.group2[order(nodes.with.group2$ID), ]

# links 
links.init &lt;- merge(
  merge(
    comp.officers[, list(value = .N), by = c(&quot;name.clean&quot;, &quot;name.company2&quot;)]
    , node0, by.x = &quot;name.company2&quot;, by.y = &quot;name&quot;, all.x = T)
  , node0, by.x = &quot;name.clean&quot;, by.y = &quot;name&quot;, all.x = T)

links2 &lt;- data.table(links.init[, list(source = ID.x, target = ID.y
                      , value = value)])</code></pre>

But the result is as expected, companies cluster by country. The [full result](http://data-laborer.eu/Pages/Force_field_company.html) is here, a bit heavy to be loaded here.

The big central cluster is made of british companies. Without the title of the officers, we can now link the british activity and the US one, through one man, Philippe Crouzat which definitely seems a key officer of EDF.


<pre><code class="prettyprint ">forceNetwork(Links = links2, Nodes = node2, Source = &quot;source&quot;,
             Target = &quot;target&quot;, Value = &quot;value&quot;, NodeID = &quot;name&quot;,
             Group = &quot;group&quot;, opacity = 1, zoom = TRUE)</code></pre>

![Full force field](http://data-laborer.eu/assets/images/special/Open_corporqte_edf_jurisdiction_force_network.png)
