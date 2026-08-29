// deno-fmt-ignore-file
// deno-lint-ignore-file
// This code was bundled using `deno bundle` and it's not recommended to edit it manually

function attachTooltip(cy, attributes) {
    if (!attributes) return ()=>{};
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
    const hide = ()=>{
        tooltip.style.display = "none";
    };
    const show = (event)=>{
        const content = event.target.data("tooltip");
        if (!content) {
            hide();
            return;
        }
        const pointer = event.originalEvent;
        tooltip.textContent = content;
        tooltip.style.display = "block";
        const gap = 12;
        tooltip.style.left = pointer.clientX + tooltip.offsetWidth + gap > window.innerWidth ? `${pointer.clientX - tooltip.offsetWidth - gap}px` : `${pointer.clientX + gap}px`;
        tooltip.style.top = `${pointer.clientY + gap}px`;
    };
    let disposed = false;
    const dispose = ()=>{
        if (disposed) return;
        disposed = true;
        cy.off("mouseover mousemove", "node, edge", show);
        cy.off("mouseout remove", "node, edge", hide);
        cy.off("pan zoom tap", hide);
        cy.off("destroy", dispose);
        tooltip.remove();
    };
    cy.on("mouseover mousemove", "node, edge", show);
    cy.on("mouseout remove", "node, edge", hide);
    cy.on("pan zoom tap", hide);
    cy.on("destroy", dispose);
    return dispose;
}
export { attachTooltip as attachTooltip };

