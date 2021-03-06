#Created April 4, 2008 
#seriously modified January, 2009 to generate sem code 

#  January 12, 2009  - still can not get latent Xs to line up if correlated
#  January 19, 2009     Added the ability to draw structures from omega output
#   More importantly, added the ability to create sem model matrices for the sem package of John Fox
#   These models will not be completely identified for certain higher order structures and require hand tuning.
#   January 30, 2009 to allow for hierarchical factor structures
"structure.graph" <-
function(fx,Phi=NULL,fy=NULL, out.file=NULL,labels=NULL,cut=.3,errors=TRUE,simple=TRUE,regression=FALSE,
   size=c(8,6), node.font=c("Helvetica",14),
    edge.font=c("Helvetica", 10),  rank.direction=c("RL","TB","LR","BT"), digits=1,title="Structural model", ...){
    	if (!requireNamespace('Rgraphviz')) {stop("I am sorry, you need to have loaded the Rgraphviz package")
    	#create several dummy functions to get around the "no visible global function definition" problem
    	nodes <- function() {}
    	addEdge <- function() {}
    	subGraph <- function(){}
    	}
 xmodel <- fx
 ymodel <- fy
 if(!is.null(class(xmodel)) && (length(class(xmodel))>1)) {
   if(class(xmodel)[1] =="psych" && class(xmodel)[2] =="omega") {
    Phi <- xmodel$schmid$phi
    xmodel <- xmodel$schmid$oblique} else {
   if(class(xmodel)[1] =="psych" && ((class(xmodel)[2] =="fa") | (class(xmodel)[2] =="principal"))) { if(!is.null(xmodel$Phi)) Phi <- xmodel$Phi
        xmodel <- as.matrix(xmodel$loadings)} 
         }} else {
 if(!is.matrix(xmodel) & !is.data.frame(xmodel) &!is.vector(xmodel))  {
        if(!is.null(xmodel$Phi)) Phi <- xmodel$Phi
        xmodel <- as.matrix(xmodel$loadings)
      } else {xmodel <- xmodel} 
     }
      
 if(!is.matrix(xmodel) ) {factors <- as.matrix(xmodel)} else {factors <- xmodel}
 
 
 
  rank.direction <- match.arg(rank.direction)
  #first some basic setup parameters 
  num.y <- 0   #we assume there is nothing there
  num.var <- num.xvar <- dim(factors)[1]   #how many x variables?
  
  if (is.null(num.xvar) ){num.xvar <- length(factors)
                          num.xfactors <- 1} else {
   num.factors <-  num.xfactors <- dim(factors)[2]}
  
   
   if(is.null(labels)) {vars <- xvars <-  rownames(xmodel)} else { xvars <-  vars <- labels}
   

  if(is.null(vars) ) {vars <- xvars <- paste("x",1:num.xvar,sep="")  }
  fact <- colnames(xmodel)
  if (is.null(fact)) { fact <- paste("X",1:num.xfactors,sep="") }
  
   num.yfactors <- 0
   if (!is.null(ymodel)) { 
   if(is.list(ymodel) & !is.data.frame(ymodel)  ) {ymodel <- as.matrix(ymodel$loadings)} else {ymodel <- ymodel}   
 if(!is.matrix(ymodel) ) {y.factors <- as.matrix(ymodel)} else {y.factors <- ymodel}
   
   num.y <- dim(y.factors)[1] 
      if (is.null(num.y)) {
         num.y <- length(ymodel)
         num.yfactors <- 1} else {
         num.yfactors <- dim(y.factors)[2]
        }  
      
     yvars <- rownames(ymodel)
     if(is.null(yvars)) {yvars <- paste("y",1:num.y,sep="")  }
     if(is.null(labels)) {vars <- c(xvars,yvars)} else {yvars <- labels[(num.xvar+1):(num.xvar+num.y)]} 
     
      yfact <- colnames(ymodel)
      if(is.null(yfact)) {yfact <- paste("Y",1:num.yfactors,sep="") }
      fact <- c(fact,yfact)
     num.var <- num.xvar + num.y
     num.factors <- num.xfactors + num.yfactors
     }
    
   # sem <- matrix(rep(NA),6*(num.var*num.factors + num.factors),ncol=3)
    sem <- matrix(NA,nrow=6*(num.var*num.factors + num.factors),ncol=3)
    colnames(sem) <- c("Path","Parameter","Value")
  
   
   edge.weights <- rep(1,num.var*2*num.factors)
    
   #now draw the x part
   if(!regression) {    #the normal condition is to draw a latent model
   k <- num.factors  
      
   clust.graph <-  new("graphNEL",nodes=c(vars,fact),edgemode="directed")
   graph.shape <- c(rep("box",num.var),rep("ellipse",num.factors))  #define the shapes
   if (num.y > 0) {graph.rank <- c(rep("min",num.xvar),rep("max",num.y),rep("same",num.xfactors),rep("",num.yfactors))} else {
                  graph.rank <- c(rep("min",num.var*2),rep("",num.factors))} 
   names(graph.shape) <- nodes(clust.graph)
   names(graph.rank) <- nodes(clust.graph)
   edge.label <- rep("",num.var*2*k)  #makes too many, but in case of a fully saturated model, this might be necessary
   edge.name <- rep("",num.var*2*k)
   names(edge.label) <-  seq(1:num.var*2*k) 
   edge.dir <-rep("forward",num.var*2*k)
   
   edge.arrows <-rep("open",num.var*2*k)
   #edge.weights <- rep(1,num.var*2*k)
   

  if (num.xfactors ==1) { 
       
    for (i in 1:num.xvar) { clust.graph <- addEdge(fact[1], vars[i], clust.graph,1) 
                                           if(is.numeric(factors[i])) {edge.label[i] <- round(factors[i],digits)} else {edge.label[i] <- factors[i]}
                                           edge.name[i] <- paste(fact[1],"~",vars[i],sep="")
                          sem[i,1] <- paste(fact[1],"->",vars[i],sep="")
                          if(is.numeric(factors[i])) {sem[i,2] <- vars[i]} else {sem[i,2] <- factors[i] }
                        }  
                        k <- num.xvar+1 
      } else {         #end of if num.xfactors ==1 
        #all loadings > cut in absolute value
                   k <- 1
                   for (i in 1:num.xvar) {
                   for (f in 1:num.xfactors) { #if (!is.numeric(factors[i,f]) ||  (abs(factors[i,f]) > cut))
                   if((!is.numeric(factors[i,f] ) && (factors[i,f] !="0"))||  ((is.numeric(factors[i,f]) && abs(factors[i,f]) > cut ))) {
               clust.graph <- addEdge(fact[f], vars[i], clust.graph,1) 
                               if(is.numeric(factors[i,f])) {edge.label[k] <- round(factors[i,f],digits)} else {edge.label[k] <- factors[i,f]}
                              edge.name[k] <- paste(fact[f],"~",vars[i],sep="")
                              sem[k,1] <- paste(fact[f],"->",vars[i],sep="")
                             if(is.numeric(factors[i,f])) {sem[k,2] <- paste("F",f,vars[i],sep="")} else {sem[k,2] <- factors[i,f]}
                              k <- k+1 }   #end of if 
                         }  
                        }      
       } 
        if(errors) {  for (i in 1:num.xvar) { clust.graph <- addEdge(vars[i], vars[i], clust.graph,1)  
                                          edge.name[k] <-   paste(vars[i],"~",vars[i],sep="")
                                          edge.arrows[k] <- "closed"
                                          sem[k,1] <- paste(vars[i],"<->",vars[i],sep="")
                                          sem[k,2] <- paste("x",i,"e",sep="")
                    k <- k+1 }
        }
    } else  {   #the regression case
       if (title=="Structural model") title <- "Regression model"
       k <- num.var+1
       yvars <- "Y1"
        
       clust.graph <-  new("graphNEL",nodes=c(vars,yvars),edgemode="directed")
       graph.rank <- c(rep("min",num.var),rep("",1))
        names(graph.rank) <- nodes(clust.graph)
       graph.shape <- rep("box",k)  #define the shapes
        names(graph.shape) <- nodes(clust.graph)
         graph.rank <- c(rep("min",num.var),rep("",1))
        names(graph.rank) <- nodes(clust.graph)
        edge.label <- rep("",k)  #makes too many, but in case of a fully saturated model, this might be necessary
   edge.name <- rep("",k)
   names(edge.label) <-  seq(1:k) 
   edge.dir <-rep("back",k)
   names(edge.dir) <-rep("",k)
   edge.arrows <-rep("open",k)
  # names(edge.arrows) <-rep("",k)
   for (i in 1:num.xvar) { clust.graph <- addEdge(yvars,vars[i], clust.graph,1) 
                                           if(is.numeric(vars[i])) {edge.label[i] <- round(factors[i],digits)} else {edge.label[i] <- factors[i]}
                                           edge.name[i] <- paste(yvars,"~",vars[i],sep="")
                        }  
    }
       
  #now, if there is a ymodel, do it for y model 
  
  if(!is.null(ymodel)) { 
  if (num.yfactors ==1) {     
    for (i in 1:num.y) { clust.graph <- addEdge( yvars[i],fact[1+num.xfactors], clust.graph,1) 
                         if(is.numeric(y.factors[i] ) ) {edge.label[k] <- round(y.factors[i],digits) } else {edge.label[k] <- y.factors[i]}
                         edge.name[k] <- paste(yvars[i],"~",fact[1+num.xfactors],sep="")
                         edge.dir[k] <- paste("back")
                          sem[k,1] <- paste(fact[1+num.xfactors],"->",yvars[i],sep="")
                           if(is.numeric(y.factors[i] ) ) {sem[k,2] <- paste("Fy",yvars[i],sep="")} else {sem[k,2] <- y.factors[i]}
                         k <- k +1
                        }                      
      } else {   #end of if num.yfactors ==1 
        #all loadings > cut in absolute value
                   for (i in 1:num.y) {
                   for (f in 1:num.yfactors) { 
                    if((!is.numeric(y.factors[i,f] ) && (y.factors[i,f] !="0"))||  ((is.numeric(y.factors[i,f]) && abs(y.factors[i,f]) > cut ))) {clust.graph <- addEdge( vars[i+num.xvar],fact[f+num.xfactors], clust.graph,1) 
                         if(is.numeric(y.factors[i,f])) {edge.label[k] <- round(y.factors[i,f],digits)} else {edge.label[k] <-y.factors[i,f]}
                         edge.name[k] <- paste(vars[i+num.xvar],"~",fact[f+num.xfactors],sep="")
                          edge.dir[k] <- paste("back")
                           sem[k,1] <- paste(fact[f+num.xfactors],"->",vars[i+num.xvar],sep="")
                           if(is.numeric(y.factors[i,f])) { sem[k,2] <- paste("Fy",f,vars[i+num.xvar],sep="")} else {sem[k,2] <- y.factors[i,f]}
                         k <- k+1 }   #end of if 
                         }  #end of factor
                        } # end of variable loop
           
       }  
       if(errors) {  for (i in 1:num.y) { clust.graph <- addEdge(vars[i+num.xvar], vars[i+num.xvar], clust.graph,1)
                    edge.name[k] <-   paste(vars[i+num.xvar],"~",vars[i+num.xvar],sep="")
                    edge.dir[k] <- paste("back")
                    edge.arrows[k] <- "closed"
                    sem[k,1] <- paste(vars[i+num.xvar],"<->",vars[i+num.xvar],sep="")
                    sem[k,2] <- paste("y",i,"e",sep="")
                    k <- k+1 }}
  
  }   #end of if.null(ymodel)
                
 nAttrs <- list()  #node attributes
 eAttrs <- list()  #edge attributes


 if (!is.null(labels)) {var.labels <- c(labels,fact)
  names(var.labels) <-  nodes(clust.graph)
  nAttrs$label <- var.labels
  names(edge.label) <- edge.name
  } 

if(!regression) {
  if(!is.null(Phi)) {if (!is.matrix(Phi)) { if(!is.null(fy)) {Phi <- matrix(c(1,0,Phi,1),ncol=2)} else {Phi <- matrix(c(1,Phi,Phi,1),ncol=2)}} 
 
 if(num.xfactors>1) {for (i in 2:num.xfactors) { #first do the correlations within the f set
      for (j in 1:(i-1)) {if((!is.numeric(Phi[i,j] ) && ((Phi[i,j] !="0")||(Phi[j,i] !="0")))||  ((is.numeric(Phi[i,j]) && abs(Phi[i,j]) > cut ))) {
                            clust.graph <- addEdge( fact[i],fact[j],clust.graph,1)
                           if (is.numeric(Phi[i,j])) { edge.label[k] <- round(Phi[i,j],digits)} else {edge.label[k] <- Phi[i,j]}
                            edge.name[k] <- paste(fact[i],"~",fact[j],sep="")
                            
                           if(!is.numeric(Phi[i,j] )) {if(Phi[i,j] == Phi[j,i] ) {
                                                      	edge.dir[k] <- "both"
                                                     	sem[k,1]  <- paste(fact[i],"<->",fact[j],sep="")
                                                     	sem[k,2] <-  paste("rF",i,"F",j,sep="")} else {
                                                     	
                                                     	    if(Phi[i,j] !="0") { edge.dir[k] <- "forward"
                                                      		sem[k,1]  <- paste(fact[i]," ->",fact[j],sep="")
                                                      		sem[k,2] <-  paste("rF",i,"F",j,sep="")} else {
                                                      edge.dir[k] <- "back"
                                                      sem[k,1]  <- paste(fact[i],"<-",fact[j],sep="")
                                                      sem[k,2] <-  paste("rF",i,"F",j,sep="")} 
                                                     	
                                                     	} 
                                                     	
                                                     	} else {  #is.numeric
                            sem[k,1]  <- paste(fact[i],"<->",fact[j],sep="")
                            edge.dir[k] <- "both"
                             if (is.numeric(Phi[i,j])) {sem[k,2] <-  paste("rF",i,"F",j,sep="")} else {sem[k,2] <- Phi[i,j] } }
                             edge.weights[k] <- 1
                                   
                            k <- k + 1} }
                            
                            }
                            }  #end of correlations within the fx set
      if(!is.null(ymodel)) {
                  for (i in 1:num.xfactors) { 
                      for (j in 1:num.yfactors) {
                      if((!is.numeric(Phi[j+num.xfactors,i] ) && (Phi[j+num.xfactors,i] !="0"))||  ((is.numeric(Phi[j+num.xfactors,i]) && abs(Phi[j+num.xfactors,i]) > cut ))) {
                       clust.graph <- addEdge( fact[j+num.xfactors],fact[i],clust.graph,1)
                       if (is.numeric(Phi[j+num.xfactors,i])) { edge.label[k] <- round(Phi[j+num.xfactors,i],digits)} else {edge.label[k] <- Phi[j+num.xfactors,i]}
                       
                       edge.name[k] <- paste(fact[j+num.xfactors],"~",fact[i],sep="")
                       if(Phi[j+num.xfactors,i]!=Phi[i,j+num.xfactors]) {edge.dir[k] <- "back"
                       sem[k,1]  <- paste(fact[i],"->",fact[j+num.xfactors],sep="") } else {
                       edge.dir[k] <- "both"
                       sem[k,1]  <- paste(fact[i],"<->",fact[j+num.xfactors],sep="")}
                       
                        if (is.numeric(Phi[j+num.xfactors,i])) {sem[k,2] <-  paste("rX",i,"Y",j,sep="")} else {sem[k,2] <- Phi[j+num.xfactors,i] } 
                       k <- k + 1 }
                        }
                      
                  }
                  }
                          
      }   
     } else {if(!is.null(Phi)) {if (!is.matrix(Phi))  Phi <- matrix(c(1,Phi,0,1),ncol=2) 
        for (i in 2:num.xvar) {
             for (j in 1:(i-1))  {
                clust.graph <- addEdge( vars[i],vars[j],clust.graph,1)
                if (is.numeric(Phi[i,j])) { edge.label[k] <- round(Phi[i,j],digits)} else {edge.label[k] <- Phi[i,j]}
                edge.name[k] <- paste(vars[i],"~",vars[j],sep="")
                if(Phi[i,j] != Phi[j,i]){edge.dir[k] <- "back"} else {edge.dir[k] <- "both"}
               k <- k + 1            }}
                              }
              edge.arrows <- rep("open",k)
     }
     
     for(f in 1:num.factors) {
        sem[k,1]  <- paste(fact[f],"<->",fact[f],sep="")
        sem[k,3] <-  "1"
         k <- k+1
     }
  
  obs.xvar <- subGraph(vars[1:num.xvar],clust.graph)
if (!is.null(ymodel)) {obs.yvar <- subGraph(vars[(num.xvar+1):num.var],clust.graph)}
obs.var <- subGraph(vars,clust.graph)
 if(!regression) {cluster.vars <- subGraph(fact,clust.graph) } else {cluster.vars <- subGraph(yvars,clust.graph) }
 observed <- list(list(graph=obs.xvar,cluster=TRUE,attrs=c(rank="min")))
 
 
 names(edge.label) <- edge.name
 names(edge.dir) <- edge.name
 names(edge.arrows) <- edge.name
 names(edge.weights) <- edge.name
 nAttrs$shape <- graph.shape
 nAttrs$rank <- graph.rank
 eAttrs$label <- edge.label

 eAttrs$dir<- edge.dir
 eAttrs$arrowhead <- edge.arrows
 eAttrs$arrowtail<- edge.arrows
 eAttrs$weight <- edge.weights
 
 attrs <- list(node = list(shape = "ellipse", fixedsize = FALSE),graph=list(rankdir=rank.direction, fontsize=6,bgcolor="white" ))
 
 
if (!is.null(ymodel)) {observed <- list(list(graph=obs.xvar,cluster=TRUE,attrs=c(rank="sink")),list(graph=obs.yvar,cluster=TRUE,attrs=c(rank="source"))) } else {
                       observed <- list(list(graph=obs.xvar,cluster=TRUE,attrs=c(rank="max")))}
 plot(clust.graph, nodeAttrs = nAttrs, edgeAttrs = eAttrs, attrs = attrs,subGList=observed,main=title) 
if(!is.null(out.file) ){toDotty(clust.graph,out.file,nodeAttrs = nAttrs, edgeAttrs = eAttrs, attrs = attrs) }

#return(list(nodeAttrs = nAttrs, edgeAttrs = eAttrs, attrs = attrs))  #useful for debugging 

model=sem[1:(k-1),]
class(model) <- "mod"   #suggested by John Fox to make the output cleaner
invisible(model)
   }
   
 
