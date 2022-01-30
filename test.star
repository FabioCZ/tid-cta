load("render.star", "render")


def main():
    return render.Root(
        child = render.Column(
            children=[
                render.Text("This works"),
                printRedText("This doesn't"),
                printRedText2(render, "Neither does this")
            ]
        )
    )

def printRedText(text):
    render.Text(content=text, color="#f00")

def printRedText2(r, text):
    r.Text(content=text, color="#f00")
