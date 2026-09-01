#contrastive graph clustering function
run_contrastive_clustering <- function(od, group_name, Z_init, K) {
  
  od <- od[start_station %in% station_ids &
             end_station %in% station_ids]
  
  #positive pair
  setorder(od, start_station, -weight)
  
  # each node's top-k destination
  positive_pairs <- od[ , head( .SD, k_positive), by = start_station]
  
  positive_pairs <- positive_pairs[ , .(i = start_station, j = end_station, weight = weight)]
  
  # station ID -> index
  positive_pairs <- merge(
    positive_pairs,
    station_index,
    by.x = "i",
    by.y = "대여소ID")
  
  setnames(
    positive_pairs,
    "index",
    "i_index")
  
  positive_pairs <- merge(
    positive_pairs,
    station_index,
    by.x = "j",
    by.y = "대여소ID")
  
  setnames(
    positive_pairs,
    "index",
    "j_index")
  
  #positive weight
  positive_pairs[ , weight_scaled := log1p(weight)]
  
  #normalization
  positive_pairs[ , weight_scaled := weight_scaled / mean(weight_scaled)]
  
  #negative pair
  neighbor_list <- split(od$end_station, od$start_station)
  negative_list <- vector("list",length(station_ids))
  
  for (x in seq_along(station_ids)) {
    current_station <- station_ids[x]
    connected <- neighbor_list[[as.character(current_station)]]
    
    if (is.null(connected)) {connected <- station_ids[0]}
    
    # self loop + already OD exsit station exclude at negative
    candidates <- setdiff(
      station_ids,
      c(current_station, connected))
    
    if (length(candidates) == 0) {
      next}
  
    selected <- sample(candidates,
                       size = min(k_negative, length(candidates)),
                       replace = FALSE)
    
    negative_list[[x]] <- data.table(
      i = current_station,
      j = selected)
  }
  
  negative_pairs <- rbindlist(negative_list, use.names = TRUE)
  
  #station index merge
  negative_pairs <- merge(
    negative_pairs,
    station_index,
    by.x = "i",
    by.y = "대여소ID")
  
  setnames(
    negative_pairs,
    "index",
    "i_index")
  
  negative_pairs <- merge(
    negative_pairs,
    station_index,
    by.x = "j",
    by.y = "대여소ID")
  
  setnames(
    negative_pairs,
    "index",
    "j_index")
  
  #vector about loss calculation
  pos_i <- positive_pairs$i_index
  pos_j <- positive_pairs$j_index
  pos_w <- positive_pairs$weight_scaled
  
  neg_i <- negative_pairs$i_index
  neg_j <- negative_pairs$j_index
  
  #contrastive loss
  contrastive_loss <- function(
    z_vector) {
    Z <- matrix(
      z_vector,
      nrow = n_nodes,
      ncol = embedding_dim
    )
    
    #positive loss 
    pos_diff <-
      Z[pos_i, , drop = FALSE] -
      Z[pos_j, , drop = FALSE]
    
    pos_dist_sq <- rowSums(pos_diff^2)
    
    pos_loss <- mean(pos_w * pos_dist_sq)
    
    #negative loss 
    neg_diff <- Z[neg_i, , drop = FALSE] - Z[neg_j, , drop = FALSE]
    
    neg_dist <- sqrt(rowSums(neg_diff^2) +1e-8)
    
    neg_loss <- mean(pmax(0, margin -neg_dist)^2)
    
    #preservation loss
    preservation_loss <- mean((Z - Z_init)^2)
    
    #total
    total_loss <- pos_loss + lambda_neg * neg_loss + gamma * preservation_loss
    
    return(total_loss)
  }
  
  #initial loss
  initial_loss <- contrastive_loss(as.vector(Z_init))
  
  #optimization
  optimization_result <- optim(par = as.vector(Z_init),
    fn = contrastive_loss, method = "L-BFGS-B",
    control = list(maxit = 50, trace = 1))
  
  #final representation
  Z <- matrix(optimization_result$par, nrow = n_nodes, ncol = embedding_dim)
  
  #k-means
  set.seed(123)
  km <- kmeans(Z, centers = K, nstart = 50, iter.max = 100)
  
  #result
  result <- data.table(
    대여소ID = station_ids,
    Z1 = Z[, 1],
    Z2 = Z[, 2],
    cluster = km$cluster,
    time_group = group_name
  )
  
  return(
    list(result =result,
      embedding = Z,
      kmeans = km,
      positive_pairs = positive_pairs,
      negative_pairs = negative_pairs,
      initial_loss = initial_loss,
      final_loss = optimization_result$value
    )
  )
}

#run
set.seed(123)
morning_result <- run_contrastive_clustering(
  od = morning_od,
  group_name = "morning_commute",
  Z_init = Z_init,
  K = K
)

set.seed(123)
noncommute_result <- run_contrastive_clustering(
  od = noncommute_od,
  group_name = "non_commute",
  Z_init = Z_init,
  K = K
)

set.seed(123)
evening_result <- run_contrastive_clustering(
  od = evening_od,
  group_name = "evening_commute",
  Z_init = Z_init,
  K = K
)
