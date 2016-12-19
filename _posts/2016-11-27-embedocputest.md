---
layout: single
title: "Include R Output in your Blog Pages with Opencpu"
categories: [hack]
tags: [R, opencpu, package, js]
date: 2016-11-27
excerpt: Short exemple of how to include R output in a blog post with opencpu
teaser: assets/images/TheRapeofEuropa.png
---

Todays blog post is more a note than a full blog post.

On my previous post, opencpu was used to create a back-end environment for a flexdashboard dashboard.

On that post, I use a bit of js to include dynamic plot into my web page.

<!--html_preserve--><script src="https://code.jquery.com/jquery-1.11.1.min.js"></script><!--/html_preserve--><!--html_preserve--><script src="https://cdn.opencpu.org/opencpu-0.4.js"></script><!--/html_preserve--><!--html_preserve--><script>ocpu.seturl('https://yvescr.ocpu.io/flexocpu/R')</script><!--/html_preserve-->

## Set up

It is possible to include js directly in your .rmd. I prefer for small piece of code to use `htmltools` but it is not mandatory:


<pre><code class="prettyprint "># client library for opencpu:
htmltools::tags$script(src=&quot;https://code.jquery.com/jquery-1.11.1.min.js&quot;)
htmltools::tags$script(src=&quot;https://cdn.opencpu.org/opencpu-0.4.js&quot;)

# set page to communicate to with &quot;mypackage&quot; on server below
htmltools::tags$script(&quot;ocpu.seturl('https://yvescr.ocpu.io/flexocpu/R')&quot;)</code></pre>

## Plot 

Now, we use the `.rplot` function to call plot. here, with a parameter of 1.

It is indeed useless if the plot is not a dynamic one. It is better in that case to include a fixed image.

The code used to include this post:


<pre><code class="prettyprint ">&lt;script&gt;
$(function(){ 
  $(&quot;#plottest&quot;).rplot(&quot;plotind&quot;, {id : Number(1)});
})
&lt;/script&gt;

&lt;div id=&quot;plottest&quot; style=&quot;height: 270px&quot;&gt; </code></pre>

<script>
$(function(){ 
  $("#plottest").rplot("plotind", {id : Number(1)});
})
</script>

<div id="plottest" style="height: 270px"> 

## Dynamic plot

With a bit of js, we can easily complexify the process to make it reactive:


<pre><code class="prettyprint ">&lt;script&gt; 

$(function(){

  var paramid = 1;

  var req = $(&quot;#plotdiv&quot;).rplot(&quot;plotind&quot;, {id : Number(paramid)});

  var req2 = ocpu.rpc(&quot;gethowel&quot;, {id : Number(paramid)},
      function(output){ console.log(output)});

  $(&quot;#idsubmit&quot;).click(function(e){
  
  var paramid = $(&quot;#myid&quot;).val();
  
    var req = $(&quot;#plotdiv&quot;).rplot(&quot;plotind&quot;, {id : Number(paramid)});

  });

});
  
&lt;/script&gt;</code></pre>

And the interface:


<pre><code class="prettyprint ">htmltools::tags$input(type=&quot;integer&quot;, class=&quot;form-control&quot;, id=&quot;myid&quot;, value=&quot;1&quot;, style = &quot;width: 90%;&quot;)
htmltools::tags$button(&quot;Update dashboard!&quot;, type=&quot;submit&quot;, id=&quot;idsubmit&quot;, class=&quot;btn btn-default&quot;)</code></pre>


<pre><code class="prettyprint ">htmltools::tags$div(id=&quot;plotdiv&quot;, style=&quot;height: 270px&quot;)</code></pre>


<script> 

$(function(){

  var paramid = 1;

  var req = $("#plotdiv").rplot("plotind", {id : Number(paramid)});

  var req2 = ocpu.rpc("gethowel", {id : Number(paramid)},
      function(output){ console.log(output)});

  $("#idsubmit").click(function(e){
  
  var paramid = $("#myid").val();
  
    var req = $("#plotdiv").rplot("plotind", {id : Number(paramid)});

  });

});
  
</script>

The result is a dynamic plot inside the blog post.

You can enter any integer between 1 and 544:

<!--html_preserve--><input type="integer" class="form-control" id="myid" value="1" style="width: 90%;"/><!--/html_preserve--><!--html_preserve--><button type="submit" id="idsubmit" class="btn btn-default">Update dashboard!</button><!--/html_preserve-->

<!--html_preserve--><div id="plotdiv" style="height: 270px"></div><!--/html_preserve-->

The same can be done to create dynamic json or any htmlwidget output.
