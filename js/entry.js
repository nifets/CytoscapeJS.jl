import cytoscape from "cytoscape"
import fcose from "cytoscape-fcose"
import cola from "cytoscape-cola"

cytoscape.use(fcose)
cytoscape.use(cola)

window.cytoscape = cytoscape
