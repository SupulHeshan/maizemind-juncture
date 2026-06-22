"""Button component for the Jac client application."""

def:pub Button(props: any) -> JsxElement {
    label     = props.label;
    onClick   = props.onClick;
    variant   = props.variant   if props.variant   else "primary";
    disabled  = props.disabled  if props.disabled  else False;
    toggle    = props.toggle    if props.toggle    else False;
    className = props.className if props.className else "";

    resolvedClassName = "button button-" + variant;
    if toggle    { resolvedClassName += " button-toggle"; }
    if className { resolvedClassName += " " + className; }

    return
        <button className={resolvedClassName} onClick={onClick} disabled={disabled}>
            {label}
        </button>;
}
