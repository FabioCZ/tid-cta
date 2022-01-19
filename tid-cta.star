load("render.star", "render")
load("http.star", "http")

CTA_MAP_BLUE_LINE_URL = "https://www.transitchicago.com/traintracker/PredictionMap/tmTrains.aspx?line=B&MaxPredictions=10"
TARGET_STATION = 40570.0

def hasTargetPrediction(preds):
    match = [x for x in preds if x[0] == TARGET_STATION]
    return len(match) == 1

def sorter(k):
    raw = k.split("/")[0]
    return int(raw)

def getPredPairs(markers):
    preds = []
    for x in markers:
        time = ""
        remark = ""
        if x["DestName"] == "Rosemont":
            remark = "/R"
        elif x["DestName"] == "Jefferson Park":
            remark = "/J"
        elif x["DestName"].startswith("UIC"):
            remark = "/U"
        elif x["DestName"].startswith("O'Hare") or x["DestName"] == "Forest Park":
            remark = ""
        else:
            remark = "/!"
        pred = [y for y in x["Predictions"] if y[0] == TARGET_STATION][0][2]
        if pred == "<b>Due</b>":
            time = "1"
        else:
            time = pred.split(">")[1].split("<")[0]
        preds.append(time + remark)
    return sorted(preds, key=sorter)


def main():
    rep = http.get(CTA_MAP_BLUE_LINE_URL)
    if rep.status_code != 200:
        fail("Coindesk request failed with status %d", rep.status_code)

    allTrains = rep.json()["dataObject"][0]["Markers"]
    caliPredictions = [x for x in allTrains if hasTargetPrediction(x["Predictions"])]
    toOhare = [x for x in caliPredictions if x["DestName"].startswith("O'Hare") or x["DestName"] == "Rosemont" or x["DestName"] == "Jefferson Park"]
    toFP = [x for x in caliPredictions if x["DestName"] == "Forest Park" or x["DestName"].startswith("UIC")]

    predsOhare = getPredPairs(toOhare)
    predsFP = getPredPairs(toFP)

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 2, height = 13),
                        render.Text(content = "ORD:", font = "6x13", height = 13, color = "#0af"),
                        render.WrappedText(content = ",".join(predsOhare), font = "6x13", height = 15)
                    ]
                ),
                render.Box(height = 1, color = "#fff", padding = 1),
                render.Row(
                    children = [
                        render.Box(width = 2, height = 13),
                        render.Text(content = "F P:", font = "6x13", height = 13, color = "#0af"),
                        render.WrappedText(content = ",".join(predsFP), font = "6x13", height = 15)
                    ]
                )
            ]
        )
    )