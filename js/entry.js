import cytoscape from "cytoscape"
import fcose from "cytoscape-fcose"
import cola from "cytoscape-cola"
import svg from "cytoscape-svg"

cytoscape.use(fcose)
cytoscape.use(cola)
cytoscape.use(svg)

window.cytoscape = cytoscape
