# below are a set of functions adapted from the QPress R package: https://github.com/SWotherspoon/QPress
# devtools::install_github("SWotherspoon/QPress",ref="Constrain")

# community sampler that allows weights to be constrained for certain edges

community.sampler_con <- function (edges, required.groups = c(0), from, to, class) # from, to, and class arguments for constraining edges as 'High', "Med', or 'Low', just a vector
{
  if (length(from) > 0){ # here add new column to edges with high medium or low classification
  constrain <- data.frame(From = from, To = to, Class = class)
  edges$Class <- dplyr::left_join(edges, constrain)$Class
  }
  n.nodes <- length(node.labels(edges))
  weight.labels <- edge.labels(edges)
  n.edges <- nrow(edges)
  W <- matrix(0, n.nodes, n.nodes)
  lower <- ifelse(edges$Type == "U" | edges$Type == "N", -1L, 
                  0L)
  upper <- ifelse(edges$Type == "U" | edges$Type == "P" , 1L, 
                  0L)
  ## set up constraints for high, medium, low
  lower[which(edges$Class == 'H' & edges$Type == 'P')] <- 0.66667
  upper[which(edges$Class == 'H' & edges$Type == 'N')] <- -0.66667
  lower[which(edges$Class == 'M' & edges$Type == 'P')] <- 0.33334
  upper[which(edges$Class == 'M' & edges$Type == 'P')] <- 0.66666
  lower[which(edges$Class == 'M' & edges$Type == 'N')] <- -0.66666
  upper[which(edges$Class == 'M' & edges$Type == 'N')] <- -0.33334
  upper[which(edges$Class == 'L' & edges$Type == 'P')] <- 0.33333
  lower[which(edges$Class == 'L' & edges$Type == 'N')] <- -0.33333
  k.edges <- as.vector(unclass(edges$To) + (unclass(edges$From) - 
                                              1) * n.nodes)
  uncertain <- which(!(edges$Group %in% required.groups))
  expand <- match(edges$Pair[uncertain], unique(edges$Pair[uncertain]))
  n.omit <- max(0, expand)
  zs <- rep(1, n.omit)
  community <- if (n.omit > 0) {
    function() {
      r <- runif(n.edges, lower, upper)
      r[uncertain] <- r[uncertain] * zs
      W[k.edges] <- r
      W
    }
  }
  else {
    function() {
      W[k.edges] <- runif(n.edges, lower, upper)
      W
    }
  }
  select <- if (n.omit > 0) {
    function(p) {
      zs <<- rbinom(n.omit, 1, p)[expand]
    }
  }
  else {
    function(p = 0) {
      zs
    }
  }
  weights <- function(W) {
    W[k.edges]
  }
  list(community = community, select = select, weights = weights, 
       weight.labels = weight.labels, uncertain.labels = weight.labels[uncertain])
}

# community sampler that allows weights to be constrained for certain edges
# **this one also allows relative strengths of edges to be constrained
# based on 'community.ordering.sampler' function from Wotherspoon

community.sampler_con2 <- function (constrainedigraph, required.groups = c(0), from, to, class, dam.scenario = c(0)) # from, to, and class arguments for constraining edges as 'High', "Med', or 'Low', just a vector
{
  edges <- constrainedigraph$edges
  if (length(from) > 0){ # here add new column to edges with high medium or low classification
    constrain <- data.frame(From = from, To = to, Class = class)
    if(length(which(names(press.scenarios[[i]]) == 'CoastalDev')) != 0){ # only if coastal development is being perturbed do we constrain SeaLevelRise -> LandwardMang egde
    edges$Class <- dplyr::left_join(edges, constrain)$Class
    }else{
    edges$Class <- dplyr::left_join(edges, constrain)$Class
    edges <- mutate(edges, Class = ifelse(To == 'LandwardMang', 'NA', Class))
    }
  }
  n.nodes <- length(node.labels(edges))
  weight.labels <- edge.labels(edges)
  n.edges <- nrow(edges)
  W <- matrix(0, n.nodes, n.nodes)
  lower <- ifelse(edges$Type == "U" | edges$Type == "N", -1L, 
                  0L)
  upper <- ifelse(edges$Type == "U" | edges$Type == "P" , 1L, 
                  0L)
  ## set up constraints for high, medium, low
  lower[which(edges$Class == 'H' & edges$Type == 'P')] <- 0.66667
  upper[which(edges$Class == 'H' & edges$Type == 'N')] <- -0.66667
  lower[which(edges$Class == 'M' & edges$Type == 'P')] <- 0.33334
  upper[which(edges$Class == 'M' & edges$Type == 'P')] <- 0.66666
  lower[which(edges$Class == 'M' & edges$Type == 'N')] <- -0.66666
  upper[which(edges$Class == 'M' & edges$Type == 'N')] <- -0.33334
  upper[which(edges$Class == 'L' & edges$Type == 'P')] <- 0.33333
  lower[which(edges$Class == 'L' & edges$Type == 'N')] <- -0.33333
  k.edges <- as.vector(unclass(edges$To) + (unclass(edges$From) - 
                                              1) * n.nodes)
  uncertain <- which(!(edges$Group %in% required.groups))
  expand <- match(edges$Pair[uncertain], unique(edges$Pair[uncertain]))
  n.omit <- max(0, expand)
  bounds <- bound.sets(constrainedigraph)
  zs <- rep(1, length(uncertain))
  damrow <- row.names(edges[edges$From == 'Sediment' & edges$To == 'SubVol',])
  community <- if (n.omit > 0) {
    function() {
      r <- runif(n.edges, lower, upper)
      if(dam.scenario > 0){r[damrow] <- r[damrow] - r[damrow]*dam.scenario} # reduce sediment supply by dam factor
      r <- sign(r) * constraint.order(abs(r), bounds)
      r[uncertain] <- r[uncertain] * zs
      W[k.edges] <- r
      W
    }
  }
  else {
    function() {
      r <- runif(n.edges, lower, upper)
      if(dam.scenario > 0){r[damrow] <- r[damrow] - r[damrow]*dam.scenario} # reduce sediment supply by dam factor
      r <- sign(r) * constraint.order(abs(r), bounds)
      W[k.edges] <- r
      W
    }
  }
  select <- if (n.omit > 0) {
    function(p) {
      zs <<- rbinom(n.omit, 1, p)[expand]
    }
  }
  else {
    function(p = 0) {
      zs
    }
  }
  weights <- function(W) {
    W[k.edges]
  }
  list(community = community, select = select, weights = weights, 
       weight.labels = weight.labels, uncertain.labels = weight.labels[uncertain])
}


# this function doesn't monitor press perturbations to validate. 
# Instead just simulate and get stable matrices, 
# record outcome (+ve, -ve, neutral) for landward and seaward mangroves
# get weights 

system.sim_press <- function (n.sims, constrainedigraph, required.groups = c(0), from, to, class, dam.scenario = c(0), 
                              sampler = community.sampler_con2(constrainedigraph, required.groups, from, to, class, dam.scenario),  
                              perturb) {
  stableout <- list()
  stablews <- list()
  stable <- 0
  unstable <- 0
  
  edges1 <- constrainedigraph$edges
  labels <- node.labels(edges1)
  index <- function(name) {
    k <- match(name, labels)
    if (any(is.na(k))) 
      warning("Unknown nodes:", paste(name[is.na(k)], collapse = " "))
    k
  }
  
  k.perturb <- index(names(perturb))
  S.press <- double(length(labels))
  S.press[k.perturb] <- -perturb
  
  if(names(perturb) == "Dams" && length(names(perturb)) == 1){
    
    while (stable < n.sims) {
      z <- sampler$select(runif(1))
      W <- sampler$community()
      if (!stable.community(W) & !is.null(solve(W, S.press))){
        unstable <- unstable + 1
        next
      } else if(all(round(solve(W, S.press)[index(names(c('SeawardMang'=1)))], 2) == 0) == FALSE)
        next
      else{
        stable <- stable + 1
        stableout[[stable]] <- data.frame(nsim = stable, var = labels, outcome = solve(W, S.press))
        stablews[[stable]] <- data.frame(nsim = stable, param = sampler$weight.labels, weight = sampler$weights(W))
      }
    }
  }else{
    while (stable < n.sims) {
      z <- sampler$select(runif(1))
      W <- sampler$community()
      if (!stable.community(W) & !is.null(solve(W, S.press))){
        unstable <- unstable + 1
        next
      } else{
        stable <- stable + 1
        stableout[[stable]] <- data.frame(nsim = stable, var = labels, outcome = solve(W, S.press))
        stablews[[stable]] <- data.frame(nsim = stable, param = sampler$weight.labels, weight = sampler$weights(W))
      }
    }
  }
  
  stableout <- do.call(rbind, stableout)
  stablews <- do.call(rbind, stablews)
  stability <- data.frame(Num_unstable = unstable, Num_stable = stable, Pot_stability =  stable/(unstable+stable))
  list(edges = edges1, stability.df = stability, stableoutcome = stableout, stableweights = stablews)
}

# include outcome validation 

system.sim_press_valid <- function (n.sims, constrainedigraph, required.groups = c(0), from, to, class, dam.scenario = c(0), 
                              sampler = community.sampler_con2(constrainedigraph, required.groups, from, to, class, dam.scenario),  
                              perturb, monitor, epsilon = 1e-05) {
  stableout <- list()
  stablews <- list()
  stable <- 0
  unstable <- 0
  
  edges1 <- constrainedigraph$edges
  labels <- node.labels(edges1)
  index <- function(name) {
    k <- match(name, labels)
    if (any(is.na(k))) 
      warning("Unknown nodes:", paste(name[is.na(k)], collapse = " "))
    k
  }
  
  k.perturb <- index(names(perturb))
  k.monitor <- index(names(monitor))
  S.press <- double(length(labels))
  S.press[k.perturb] <- -perturb
  monitor <- sign(monitor)
  
  while (stable < n.sims) {
    z <- sampler$select(runif(1))
    W <- sampler$community()
    if (!stable.community(W) & !is.null(solve(W, S.press))){
      unstable <- unstable + 1
      next
    } else if(!is.null(tryCatch(solve(W, S.press), error = function(e) NULL)) && all(signum(s[k.monitor], epsilon) == monitor) == FALSE)
      next
    else{
      stable <- stable + 1
      stableout[[stable]] <- data.frame(nsim = stable, var = labels, outcome = solve(W, S.press))
      stablews[[stable]] <- data.frame(nsim = stable, param = sampler$weight.labels, weight = sampler$weights(W))
    }
  }
  
  stableout <- do.call(rbind, stableout)
  stablews <- do.call(rbind, stablews)
  stability <- data.frame(Num_unstable = unstable, Num_stable = stable, Pot_stability =  stable/(unstable+stable))
  list(edges = edges1, stability.df = stability, stableoutcome = stableout, stableweights = stablews)
}
# this function can only do one press scenario at a time
# unlike original 'system.simulate' which can accept models that are valid under
# multiple scenarios

system.sim_press_val <- function (n.sims, edges, required.groups = c(0), 
          sampler = community.sampler(edges, required.groups),  
          perturb, monitor, epsilon = 1e-05) {
  
  allout <- list()
  valout <- matrix(0, n.sims, length(node.labels(edges)))
  ws <- matrix(0, n.sims, nrow(edges))
  total <- 0
  stable <- 0
  accepted <- 0
  
  labels <- node.labels(edges)
  index <- function(name) {
    k <- match(name, labels)
    if (any(is.na(k))) 
      warning("Unknown nodes:", paste(name[is.na(k)], collapse = " "))
    k
  }
  
  k.perturb <- index(names(perturb))
  k.monitor <- index(names(monitor))
  S.press <- double(length(labels))
  S.press[k.perturb] <- -perturb
  monitor <- sign(monitor)
  
  while (accepted < n.sims) {
    total <- total + 1
    z <- sampler$select(runif(1))
    W <- sampler$community()
    if (!stable.community(W)) 
      next
    stable <- stable + 1
    allout[[total]] <- tryCatch(solve(W, S.press), error = function(e) NULL)
      s <- tryCatch(solve(W, S.press), error = function(e) NULL)
      val <- !is.null(s) && all(signum(s[k.monitor], epsilon) == monitor)
    if(val == FALSE)
      next
    accepted <- accepted + 1
    valout[accepted, ] <- s
    ws[accepted, ] <- sampler$weights(W)
  }
  allout <- do.call(rbind, allout)
  colnames(allout) <- node.labels(edges)
  colnames(valout) <- node.labels(edges)
  colnames(ws) <- sampler$weight.labels
  list(edges = edges, allout = allout, valout = valout, valweights = ws, total = total, stable = stable, 
       accepted = accepted)
}

# save DiagrammR plot

save_png <- function(plot, path){
  DiagrammeRsvg::export_svg(plot) %>%
    charToRaw() %>%
    rsvg::rsvg() %>%
    png::writePNG(path)
}

# Construct bounding sets used to order weights to meet the edge
# weight constraints.
# These bounds sets are used to order a set of random edge weights
# so that they meet the imposed constraints.

bound.sets <- function(constrained) {
  a <- constrained$a
  b <- constrained$b
  
  ## Find all weights bounded above by the root weight r
  bounded <- function(r) {
    v <- unique(a[b %in% r])
    repeat {
      va <- setdiff(a[b %in% v],v)
      if(length(va)==0) break;
      v <- c(va,v)
    }
    v
  }
  
  bounds <- list()
  n <- 0
  
  ## Unvisited weights
  us <- b
  ## Unbounded weights
  vs <- setdiff(b,a)
  while(length(vs) > 0) {
    for(v in vs) {
      ## Find all weights bounded by v
      bs <- bounded(v)
      if(v %in% bs) warning("Cyclic constraints found")
      bounds[[n <- n+1]] <- c(v,bs)
    }
    ## Unvisited weights
    us <- setdiff(us,vs)
    ## Weights bounded only by visited weights
    vs <- setdiff(us,a[b %in% us])
  }
  bounds
}

# Order a set of absolute edge weights to meet imposed edge weights
# constraints.

constraint.order <- function(w,bounds) {
  for(bs in bounds) {
    k <- which.max(w[bs])
    if(k!=1) w[bs[c(1,k)]] <- w[bs[c(k,1)]]
  }
  w
}
