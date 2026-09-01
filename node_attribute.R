dataset_names <- ls(pattern = "^bike_data_2[0-5][0-1][0-9]$")
end_summary_data <- data.frame()

#summary
for (name in dataset_names) {
  cat("처리 중:", name, "\n")
  
  temp_data <- get(name)
  clean_end_data <- temp_data %>%
    filter(
      !is.na(반납대여소ID),
      trimws(as.character(반납대여소ID)) != "",
      !is.na(이용거리.M.),
      !is.na(이용시간.분.)
    ) %>%
    mutate(
      반납대여소ID = as.character(반납대여소ID),
      반납일시_posix = as.POSIXct(반납일시),
      도착_시간 = as.numeric(format(반납일시_posix, "%H")),
      도착_요일 = as.numeric(format(반납일시_posix, "%u"))
    ) %>%
    filter(!is.na(반납일시_posix))
  
  current_end_summary <- clean_end_data %>%
    group_by(반납대여소ID) %>%
    summarise(
      도착_건수 = n(),
      도착_총_이용거리 = sum(이용거리.M., na.rm = TRUE),
      도착_총_이용시간 = sum(이용시간.분., na.rm = TRUE),
      도착_건수_1km_이하 = sum(이용거리.M. <= 1000, na.rm = TRUE),
      도착_건수_2km_이하 = sum(이용거리.M. <= 2000, na.rm = TRUE),
      도착_건수_출근_오전 = sum(도착_시간 >= 7 & 도착_시간 < 10, na.rm = TRUE),
      도착_건수_비출근_낮 = sum(도착_시간 >= 13 & 도착_시간 < 16, na.rm = TRUE),
      도착_건수_퇴근_저녁 = sum(도착_시간 >= 18 & 도착_시간 < 21, na.rm = TRUE),
      도착_건수_평일 = sum(도착_요일 >= 1 & 도착_요일 <= 5, na.rm = TRUE),
      도착_건수_주말 = sum(도착_요일 >= 6 & 도착_요일 <= 7, na.rm = TRUE),
      도착_건수_외국인 = if("이용자종류" %in% names(.)) {
        sum(이용자종류 == "외국인", na.rm = TRUE)
      } else {
        0
      },
      도착_q5_시간 = quantile(이용시간.분., probs = 0.05, na.rm = TRUE),
      도착_q95_시간 = quantile(이용시간.분., probs = 0.95, na.rm = TRUE),
      도착_q5_거리 = quantile(이용거리.M., probs = 0.05, na.rm = TRUE),
      도착_q95_거리 = quantile(이용거리.M., probs = 0.95, na.rm = TRUE),
      .groups = "drop"
    )
  end_summary_data <- bind_rows(end_summary_data, current_end_summary)
  rm(temp_data, clean_end_data, current_end_summary)
  gc()
}

#ratio calculate
end_station_summary_total <- end_summary_data %>%
  group_by(반납대여소ID) %>%
  summarise(
    총_도착건수 = sum(도착_건수, na.rm = TRUE),
    도착_평균_이용시간 = sum(도착_총_이용시간, na.rm = TRUE) / 총_도착건수,
    도착_평균_이용거리 = sum(도착_총_이용거리, na.rm = TRUE) / 총_도착건수,
    도착_비율_1km_이하 = sum(도착_건수_1km_이하, na.rm = TRUE) / 총_도착건수,
    도착_비율_2km_이하 = sum(도착_건수_2km_이하, na.rm = TRUE) / 총_도착건수,
    도착_비율_출근_오전 = sum(도착_건수_출근_오전, na.rm = TRUE) / 총_도착건수,
    도착_비율_비출근_낮 = sum(도착_건수_비출근_낮, na.rm = TRUE) / 총_도착건수,
    도착_비율_퇴근_저녁 = sum(도착_건수_퇴근_저녁, na.rm = TRUE) / 총_도착건수,
    도착_비율_평일 = sum(도착_건수_평일, na.rm = TRUE) / 총_도착건수,
    도착_비율_주말 = sum(도착_건수_주말, na.rm = TRUE) / 총_도착건수,
    도착_비율_외국인 = sum(도착_건수_외국인, na.rm = TRUE) / 총_도착건수,
    도착_이용시간_하위5 = sum(도착_q5_시간 * 도착_건수, na.rm = TRUE) / 총_도착건수,
    도착_이용시간_상위95 = sum(도착_q95_시간 * 도착_건수, na.rm = TRUE) / 총_도착건수,
    도착_이용거리_하위5 = sum(도착_q5_거리 * 도착_건수, na.rm = TRUE) / 총_도착건수,
    도착_이용거리_상위95 = sum(도착_q95_거리 * 도착_건수, na.rm = TRUE) / 총_도착건수,
    .groups = "drop"
  )

#rename
final_station_summary_start <- final_station_summary_ver4 %>%
  rename(
    대여소ID = 대여대여소ID,
    총_출발건수 = 총_대여건수,
    출발_평균_이용시간 = 평균_이용시간,
    출발_평균_이용거리 = 평균_이용거리,
    출발_비율_1km_이하 = 비율_1km_이하,
    출발_비율_2km_이하 = 비율_2km_이하,
    출발_비율_출근_오전 = 비율_출근_오전,
    출발_비율_비출근_낮 = 비율_비출근_낮,
    출발_비율_퇴근_저녁 = 비율_퇴근_저녁,
    출발_비율_평일 = 비율_평일,
    출발_비율_주말 = 비율_주말,
    출발_비율_외국인 = 비율_외국인,
    출발_이용시간_하위5 = 이용시간_하위5,
    출발_이용시간_상위95 = 이용시간_상위95,
    출발_이용거리_하위5 = 이용거리_하위5,
    출발_이용거리_상위95 = 이용거리_상위95
  )

end_station_summary_total_rename <- end_station_summary_total %>%
  rename(
    대여소ID = 반납대여소ID
  )

#arrival+departure
final_station_summary_ver5 <- final_station_summary_start %>%
  left_join(
    end_station_summary_total_rename,
    by = "대여소ID"
  ) %>%
  mutate(
    총_도착건수 = ifelse(is.na(총_도착건수), 0, 총_도착건수),
    
    총_이용건수 = 총_출발건수 + 총_도착건수,
    출발_도착_차이 = 총_출발건수 - 총_도착건수,
    출발_도착_격차 = abs(출발_도착_차이),
    
    출발_비중 = ifelse(총_이용건수 == 0, NA, 총_출발건수 / 총_이용건수),
    도착_비중 = ifelse(총_이용건수 == 0, NA, 총_도착건수 / 총_이용건수)
  )

#sf transition
station_sf <- final_station_summary_ver5 %>%
  filter(
    !is.na(위도),
    !is.na(경도)
  ) %>%
  st_as_sf(
    coords = c("경도", "위도"),
    crs = 4326,
    remove = FALSE
  ) %>%
  st_transform(5179)

#distacne from oneself
dist_list <- c(50, 100, 200, 300, 400, 500)

near_station_summary <- data.frame(
  대여소ID = station_sf$대여소ID,
  stringsAsFactors = FALSE
)

for (d in dist_list) {
  nearby_idx <- st_is_within_distance(
    station_sf,
    station_sf,
    dist = d
  )
  
  #exception oneself
  near_station_summary[[paste0("대여소수_", d, "m_자기제외")]] <- lengths(nearby_idx) - 1
  
  #including oneself and near station's departure
  near_station_summary[[paste0("출발건수_", d, "m_자기포함")]] <- sapply(
    nearby_idx,
    function(idx) {
      sum(station_sf$총_출발건수[idx], na.rm = TRUE)
    }
  )
  
  #including oneself and near station's arrival
  near_station_summary[[paste0("도착건수_", d, "m_자기포함")]] <- sapply(
    nearby_idx,
    function(idx) {
      sum(station_sf$총_도착건수[idx], na.rm = TRUE)
    }
  )
  
  #including oneself and near station's departure+arrival
  near_station_summary[[paste0("이용건수합_", d, "m_자기포함")]] <- sapply(
    nearby_idx,
    function(idx) {
      sum(station_sf$총_이용건수[idx], na.rm = TRUE)
    }
  )
}

final_station_summary_ver6 <- final_station_summary_ver5 %>%
  left_join(
    near_station_summary,
    by = "대여소ID"
  )