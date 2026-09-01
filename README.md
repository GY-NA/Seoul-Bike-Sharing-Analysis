### 1. Data Preprocessing

The public bicycle sharing data for Seoul was obtained from [Seoul Open Data Plaza](https://data.seoul.go.kr/). The preprocessing pipeline consists of the following steps:

* **Coordinate Merging:** Since the original trip records did not include geographic coordinates, latitude and longitude were joined from a station master dataset.
* **Node Attribute Construction:** For each station, we extracted departure and arrival metrics, including:
  * Trip duration and travel distance
  * Rental counts by foreign users
  * Usage frequency separated by weekdays vs. weekends
  * Density metrics: count of neighboring stations within distance thresholds ($200\text{m} \sim 500\text{m}$) and their cumulative trip counts
* **Filtering:** Stations with invalid/missing metadata or excessively low trip volume were excluded.

---

### 2. Graph Construction

Using the extracted station features and trip records from **August 2025**, we construct a spatial-temporal graph focusing on weekday commuting patterns:

* **Target Dataset:** Restricted to weekdays; round trips (identical rental and return stations) and invalid records were removed.
* **Time Windows:**
  * **Morning Commute:** 07:00 – 10:00
  * **Non-Commute:** 13:00 – 16:00
  * **Evening Commute:** 18:00 – 21:00

The constructed graph embeddings are trained via contrastive learning and evaluated using $k$-means clustering.

---

### 3. Model Architecture & Loss Functions

#### Positive Loss
Encourages connected/similar station pairs to have close representation vectors:

$$
\mathcal{L}_{\mathrm{pos}} = \frac{1}{|P|} \sum_{(i,j)\in P} \tilde{w}_{ij} \left\| \mathbf{z}_i - \mathbf{z}_j \right\|_2^2
$$

#### Negative Loss
Enforces a margin $m$ between dissimilar or unconnected station pairs:

$$
\mathcal{L}_{\mathrm{neg}} = \frac{1}{|N|} \sum_{(i,j)\in N} \left[ \max \left( 0,\, m - \left\| \mathbf{z}_i - \mathbf{z}_j \right\|_2 \right) \right]^2
$$

#### Preservation Loss
Regularizes latent embeddings to remain grounded relative to initial node features $\mathbf{z}^{(0)}$:

$$
\mathcal{L}_{\mathrm{preservation}} = \frac{1}{n} \sum_{i=1}^{n} \left\| \mathbf{z}_i - \mathbf{z}_i^{(0)} \right\|_2^2
$$

#### Objective Function
The combined total loss function to minimize:

$$
\mathcal{L} = \mathcal{L}_{\mathrm{pos}} + \lambda \mathcal{L}_{\mathrm{neg}} + \gamma \mathcal{L}_{\mathrm{preservation}}
$$

### Acknowledgement
This repository was developed with support from the 서울시립대학교 데이터 사이언스 플러스 차세대 융합인재 양성사업단 - http://dsplus.uos.ac.kr/
