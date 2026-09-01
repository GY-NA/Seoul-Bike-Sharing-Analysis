#time setting
#07~ 10
morning_start <- 7
morning_end <- 10

#13 ~ 15
noncommute_start <- 13
noncommute_end <- 16

#18~21
evening_start <- 18
evening_end <- 21

#Contrastive learning setting
k_positive <- 5
k_negative <- 5

#representation dimension
embedding_dim <- 2

#loss parameter
lambda_neg <- 1
gamma_anchor <- 0.1
margin <- 2

#number of K-means cluster
K <- 4

#data
trip <- as.data.table(bike_data_2508) #data name

#select col
trip <- trip[ , .(
  rental_datetime = 대여일시,
  start_station   = `대여대여소ID`,
  end_station     = `반납대여소ID`)]

#date, time conversion
trip[ , rental_datetime := ymd_hms(rental_datetime, quiet = TRUE)]

#cleaning : missing and slef-loop elimination
trip <- trip[
  !is.na(rental_datetime) &
    !is.na(start_station) &
    !is.na(end_station)]

#arrival station = departure station : elimination
trip <- trip[start_station != end_station]

#date
trip[ , rental_date := as.Date(rental_datetime)]

#day of the week (1=mon~7=sum)
trip[ , weekday_num := wday(rental_datetime, week_start = 1)]

#time
trip[ , hour := hour(rental_datetime)]

#choose weekday 
trip_weekday <- trip[weekday_num <= 5]

#time classification
trip_weekday[ , time_group :=
                fifelse(
                  hour >= morning_start &
                    hour < morning_end,
                  "morning_commute",
                  fifelse(
                    hour >= noncommute_start &
                    hour < noncommute_end,
                    "non_commute",
                  fifelse(
                      hour >= evening_start &
                      hour < evening_end,
                      "evening_commute",
                      NA_character_)))]

trip_selected <- trip_weekday[!is.na(time_group)]

#make OD graph function by time
make_od_graph <- function(data, group_name) {
  temp <- data[
    time_group == group_name
  ]
  od <- temp[ , .(
    weight = .N),
    by = .(
      start_station,
      end_station
    )
  ]
  return(od)
}

#make graph 
morning_od <- make_od_graph(trip_selected, "morning_commute")

noncommute_od <- make_od_graph(trip_selected, "non_commute")

evening_od <- make_od_graph(trip_selected, "evening_commute")

#station info
station_summary <- as.data.table(final_station_summary_ver6) #station summary(attribute) data name

station_summary <- as.data.table(final_station_summary_ver6)

station_ids <- unique(station_summary$대여소ID)

n_nodes <- length(station_ids)

#index about optimization
station_index <- data.table(
  대여소ID = station_ids,
  index = seq_along(station_ids)
)

#select node attribute
feature_cols <- c(
  "총_출발건수",
  "출발_평균_이용시간",
  "출발_평균_이용거리",
  "출발_비율_출근_오전",
  "출발_비율_퇴근_저녁",
  "출발_비율_평일",
  "총_도착건수",
  "도착_평균_이용시간",
  "도착_평균_이용거리",
  "도착_비율_출근_오전",
  "도착_비율_퇴근_저녁",
  "도착_비율_평일",
  "출발_도착_차이",
  "이용건수합_500m_자기포함",
  "대여소수_500m_자기제외")

#match station order
station_attr <- merge(
  station_index,
  station_summary,
  by = "대여소ID",
  all.x = TRUE
)

setorder(station_attr, index)

#create node attribute matrix X
X <- as.matrix(station_attr[ , ..feature_cols])

#missing -> median
colSums(is.na(X))

for (j in seq_len(ncol(X))) {
  
  missing <- is.na(X[, j])
  
  if (any(missing)) {
    X[missing, j] <- median(
      X[, j],
      na.rm = TRUE
    )
  }
}

#node attribute standardization
X_scaled <- scale(X)

#PCA innitial representation
embedding_dim <- 2

pca_result <- prcomp(
  X_scaled,
  center = FALSE,
  scale. = FALSE
)

Z_init <- pca_result$x[ , 1:embedding_dim, drop = FALSE]

Z_init <- scale(Z_init)

dim(Z_init)
