"factor.congruence" <-
function (x,y,digits=2) {
 
 if (!is.matrix(x)) {x <- x$loadings}
   if (!is.matrix(y))  { y <- y$loadings }
      
  nx<- dim(x)[2]
  ny<- dim(y)[2]
  cross<- t(y) %*% x   #inner product will have dim of ny * nx
   sumsx<- sqrt(1/diag(t(x)%*%x))   
   sumsy<- sqrt(1/diag(t(y)%*%y)) 

   result<- matrix(rep(0,nx*ny),ncol=nx)
   result<-  round(sumsy * (cross * rep(sumsx, each = ny)),digits)
   return(t(result))
   }