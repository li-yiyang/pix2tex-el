from epc.server import EPCServer

from PIL import ImageGrab
from pix2tex.cli import LatexOCR

def make_pix2tex_server():
    """Make a pix2tex server."""

    model  = LatexOCR()
    server = EPCServer(("localhost", 0))

    def clipboard():
        img = None
        try:
            img = ImageGrab.grabclipboard()
        except NotImplementedError as e:
            return f"{e}"
        return model(img)
    server.register_function(clipboard)

    return server

if __name__ == '__main__':
    server = make_pix2tex_server()
    
    server.print_port()
    server.serve_forever()
    
