library(mgcv)
library(dplyr)
library(lubridate)
set.seed(42)

# Some params
test_ratio <- 0.2

# Read the dataset from the CSV file
data_path <- "../generated/Aix-en-Provence/measures_100.csv"
df <- read.csv(data_path)
# Rename some of the columns because we can't do that in GAMA
names(df) <- gsub("string\\.d\\.", "timestamp", names(df))
names(df) <- gsub("conc_map\\.", "", names(df))
names(df) <- gsub("\\.", "", names(df))

# Cyclical encoding with a period of 1 day (since we are simulating for 1 day only)
times <- ymd_hms(df$timestamp)
cyclical_feats <- cyclic_encoding(times, c("day"))
df <- cbind(df, cyclical_feats)

# Split train/test set by splitting the cyclists, not data points
unique_agents <- unique(df$name_of_agent)
sample <- sample.int(n = length(unique_agents),
                     size = floor(test_ratio * length(unique_agents)),
                     replace = FALSE)
train_agents <- unique_agents[-sample]
test_agents  <- unique_agents[sample]
df_train <- df %>% filter(df$name_of_agent %in% train_agents)
df_test <- df %>% filter(df$name_of_agent %in% test_agents)
print(sprintf("Train set shape: (%s, %s)", nrow(df_train), ncol(df_train)))
print(sprintf("Test set shape: (%s, %s)", nrow(df_test), ncol(df_test)))

# Standardize numerical features
scaled_feats <- c("lon", "lat", "buildings_volume", "voie_1", "voie_2", "voie_3", "voie_4",
                 "road_0_4_width", "road_4_6_width",
                 "distance_to_main_road",
                 "bois", "foret", "haie")
train_feats_scaled <- scale(df_train[, scaled_feats])
df_train[, scaled_feats] <- train_feats_scaled
test_feats_scaled <- scale(df_test[, scaled_feats],
                          center=attr(train_feats_scaled, "scaled:center"),
                          scale=attr(train_feats_scaled, "scaled:scale"))
df_test[, scaled_feats] <- test_feats_scaled

mse <- function(y_true, y_pred) {
    return(mean((y_true - y_pred) ^ 2))
}
mae <- function(y_true, y_pred) {
    return(mean(abs(y_true - y_pred)))
}

# Train a GAM for each target variable
gam_models <- vector(mode="list", length=4)
ptypes <- c("NO2", "O3", "PM10", "PM25")
for (i in 1:length(ptypes)) {
    print(sprintf("Training GAM for target: %s", ptypes[i]))
    # fmla <- sprintf("%s ~ s(lon, lat) +  s(sin.day) + s(cos.day) +
    #                 s(buildings_volume) +
    #                 s(voie_1) + s(voie_2) + s(voie_3) + s(voie_4) +
    #                 s(road_0_4_width) + s(road_4_6_width) +
    #                 s(bois) + s(foret) + s(haie)",
    #                 ptypes[i])
    fmla <- sprintf("%s ~ s(lon, lat) + s(sin.day) + s(cos.day)", ptypes[i])
    fmla <- as.formula(fmla)

    # Identity link function works much better than log
    # gam_models[[i]] <- gam(fmla, data = df_train, method = "REML", family="gaussian"(link='log'))
    gam_models[[i]] <- gam(fmla, data = df_test, method = "REML", family="gaussian"(link='identity'))
    y_pred <- predict(gam_models[[i]], df_test)
    y_true <- df_test[[ptypes[i]]]
    print(sprintf("Test MAE = %s", mae(y_true, y_pred)))
}
