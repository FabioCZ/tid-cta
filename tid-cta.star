load("render.star", "render")
load("http.star", "http")
load("re.star", "re")

# For some reason https sometimes fails
CTA_MAP_BLUE_LINE_URL = "http://www.transitchicago.com/traintracker/PredictionMap/tmTrains.aspx?line=B&MaxPredictions=20"
TARGET_STATION = 40570.0

def hasTargetPrediction(preds):
    match = [x for x in preds if x[0] == TARGET_STATION]
    return len(match) == 1

def sorter(k):
    raw = re.findall(r'\d+', k)[0]
    return int(raw)

def getPredPairs(markers):
    preds = []
    for x in markers:
        time = ""
        remark = ""
        if x["DestName"] == "Rosemont":
            remark = "R"
        elif x["DestName"] == "Jefferson Park":
            remark = "J"
        elif x["DestName"].startswith("UIC"):
            remark = "U"
        elif x["DestName"].startswith("O'Hare") or x["DestName"] == "Forest Park":
            remark = ""
        else:
            remark = "!"
        pred = [y for y in x["Predictions"] if y[0] == TARGET_STATION][0][2]
        if pred == "<b>Due</b>":
            time = "0"
        else:
            timeInt = int(re.findall(r'\d+', pred)[0])
            time = str(timeInt - 1) #adj by -1 for better predictions due to sever delay
        preds.append(time + remark)
    return sorted(preds, key=sorter)

def renderLine(rr, dest, arrivals):
    render.Row(
        children = [
            render.Box(width = 1, height = 1),
            render.Box(width = 20, height = 15, color="#0af",
                child=render.Text(content = dest, font = "6x13", height = 13, color = "#fff")
            ),
            render.Marquee(width=43,
                child=render.Text(content = arrivals, font = "6x13", height = 15)
            )
        ]
    )

def firstPred(preds):
    if len(preds) > 0:
        return preds[0]
    else:
        return "nothin'"

def otherPreds(preds):
    if len(preds) == 0:
        return ""
    predsCopy = list(preds)
    predsCopy.pop(0)
    return ",".join(predsCopy)

def renderPreds(r, destName, preds):
    return r.Row(
        children = [
            r.Box(width = 1, height = 1, color="#000"),
            r.Box(width = 19, height = 13, color="#0af",
                child=r.Row(
                    children = [
                        r.Box(width=1,height=1,color="#0af"),
                        r.Text(content = destName, font = "6x13", color = "#fff")
                    ]
                )
            ),
            r.Box(width = 2, height = 1, color="#000"),
            r.Text(content=firstPred(preds), height=13, font = "6x13", color="#fb0"),
            r.Box(width = 1, height = 1, color="#000"),
            r.Marquee(width=40,
                child=r.Text(content = otherPreds(preds), height=12)
            )
        ]
    )

def renderTrainFrame(r, offset):
    return r.Row(
        children = [
            r.Box(width=offset, height=3, color="#000"),
            r.Column(
                children = [
                    r.Box(width=6, height=2, color="#888"),
                    r.Row(
                        children = [
                            r.Box(width=1,height=1,color="#000"),
                            r.Box(width=1,height=1,color="#888"),
                            r.Box(width=2,height=1,color="#000"),
                            r.Box(width=1,height=1,color="#888")
                        ]
                    )
                ]
            ),
            r.Column(
                children = [
                    r.Box(width=1,height=1,color="#000"),
                    r.Box(width=1,height=1,color="#888")
                ]
            ),
            r.Column(
                children = [
                    r.Box(width=6, height=2, color="#888"),
                    r.Row(
                        children = [
                            r.Box(width=1,height=1,color="#000"),
                            r.Box(width=1,height=1,color="#888"),
                            r.Box(width=2,height=1,color="#000"),
                            r.Box(width=1,height=1,color="#888")
                        ]
                    )
                ]
            ),
        ]
    )


def renderAnimatedTrain(r):
    frames = []
    for i in range(59,0,-1):
        frames.append(renderTrainFrame(r,i))
        frames.append(renderTrainFrame(r,i))

    return r.Animation(
        children = frames
    )

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
                render.Box(width = 1, height = 1, color="#000"),
                renderPreds(render,"ORD",predsOhare),
                renderAnimatedTrain(render),
                # render.Box(height = 1, color = "#000"),
                # render.Box(height = 2, color = "#aaa"),
                render.Box(height = 1, color="#333"),
                renderPreds(render,"FP",predsFP)
            ]
        )
    )