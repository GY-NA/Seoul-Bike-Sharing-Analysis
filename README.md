The public bicycle sharing data for Seoul can be downloaded via
\"https://data.seoul.go.kr/\". Using this shared bike data, we conducted
the following pre process\
First, because the original trip records lacked geographic coordinates
for each station, latitude and longitude were merged from a separate
master dataset.\
To construct node attributes for each station, we computed metrics for
both departures and arrivals, including trip duration, travel distance,
trip counts by foreign users, and usage counts broken down by weekdays
versus weekends.\
Additionally, for each station, we calculated the number of neighboring
stations within specific distance thresholds (200--500m) alongside their
cumulative trip counts.\
Through these preprocessing steps, stations with missing addresses or
excessively low usage volumes were excluded, resulting in the final
feature attributes.\
Furthermore, based on these constructed attributes and the trip records
from August 2025, we aim to construct a graph representation and apply
contrastive learning followed by k-means clustering.\
When constructing the graph, time windows were categorized into three
distinct periods:\
Morning Commute: 07:00--10:00\
Evening Commute: 18:00--21:00\
Non-Commute: 13:00--16:00\
Since the focus was placed on commuting versus non-commuting dynamics,
the dataset was restricted to weekdays when standard commuting occurs.
Round trips (where the rental and return stations were identical) and
records missing rental or return metadata were also filtered out.\
\
The model architecture to be trained is as follows:\
**\[POSITIVE LOSS\]**\
$$\mathcal{L}_{\mathrm{pos}}
=
\frac{1}{|P|}
\sum_{(i,j)\in P}
\tilde{w}_{ij}
\left\|
\mathbf{z}_i-\mathbf{z}_j
\right\|_2^2,$$\
\
**NEGATIVE LOSS** $$\mathcal{L}_{\mathrm{neg}}
=
\frac{1}{|N|}
\sum_{(i,j)\in N}
\left[
\max
\left(
0,\,
m-\left\|
\mathbf{z}_i-\mathbf{z}_j
\right\|_2
\right)
\right]^2$$\
\
**ANCHOR LOSS** $$\mathcal{L}_{\mathrm{anchor}}
=
\frac{1}{n}
\sum_{i=1}^{n}
\left\|
\mathbf{z}_i-\mathbf{z}_i^{(0)}
\right\|_2^2$$\
\
**OBJECTIVE FUNCTION**
$$\mathcal{L}=\mathcal{L}_{\mathrm{pos}}+ \lambda \mathcal{L}_{\mathrm{neg}}+\gamma \mathcal{L}_{\mathrm{anchor}}$$
