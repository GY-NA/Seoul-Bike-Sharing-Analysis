all_results <- rbindlist(
  list(
    morning_result$result,
    noncommute_result$result,
    evening_result$result))

#cluster size by time
cluster_size <- all_results[ , .N,
  by = .( time_group, cluster) ][
  order(time_group, cluster)]

#embedding plot
plot(
  morning_result$embedding[, 1],
  morning_result$embedding[, 2],
  col = morning_result$kmeans$cluster,
  pch = 16,
  cex = 0.5,
  xlab = "Z1",
  ylab = "Z2",
  main = "Morning Commute: 07:00-10:00"
)

plot(
  noncommute_result$embedding[, 1],
  noncommute_result$embedding[, 2],
  col = noncommute_result$kmeans$cluster,
  pch = 16,
  cex = 0.5,
  xlab = "Z1",
  ylab = "Z2",
  main = "Non-commute: 13:00-16:00"
)

plot(
  evening_result$embedding[, 1],
  evening_result$embedding[, 2],
  col = evening_result$kmeans$cluster,
  pch = 16,
  cex = 0.5,
  xlab = "Z1",
  ylab = "Z2",
  main = "Evening Commute: 18:00-21:00"
)

#same station's cluster comparision by time
cluster_wide <- dcast(
  all_results,
  대여소ID ~ time_group,
  value.var = "cluster")

head(cluster_wide)

#node attribute's mean by cluster
result_with_attr <- merge(
  all_results,
  station_summary,
  by = "대여소ID",
  all.x = TRUE)

cluster_characteristics <- result_with_attr[ ,
  lapply(.SD, mean, na.rm = TRUE), by = .(time_group, cluster),
  .SDcols = feature_cols]