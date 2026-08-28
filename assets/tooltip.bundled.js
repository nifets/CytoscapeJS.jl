// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

function attachTooltip(cy, attributes) {
    if (!attributes) return;
    const tooltip = document.createElement("div");
    Object.assign(tooltip.style, {
        position: "fixed",
        display: "none",
        pointerEvents: "none",
        zIndex: "10000"
    });
    for (const [name, value] of Object.entries(attributes)){
        if (name === "class") tooltip.className = value;
        else if (name === "style") tooltip.style.cssText += `;${value}`;
        else tooltip.setAttribute(name, value);
    }
    document.body.appendChild(tooltip);
    cy.on("mouseover mousemove", "node, edge", (event)=>{
        const content = event.target.data("tooltip");
        if (!content) return;
        const pointer = event.originalEvent;
        tooltip.textContent = content;
        tooltip.style.display = "block";
        const gap = 12;
        tooltip.style.left = pointer.clientX + tooltip.offsetWidth + gap > window.innerWidth ? `${pointer.clientX - tooltip.offsetWidth - gap}px` : `${pointer.clientX + gap}px`;
        tooltip.style.top = `${pointer.clientY + gap}px`;
    });
    cy.on("mouseout", "node, edge", ()=>{
        tooltip.style.display = "none";
    });
    cy.on("destroy", ()=>tooltip.remove());
}
export { attachTooltip as attachTooltip };

