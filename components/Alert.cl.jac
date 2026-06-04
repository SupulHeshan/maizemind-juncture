"""Alert component"""

def:pub Alert(props: any) -> JsxElement {
    title = props.title;
    description = props.description;
    children = props.children;
    variant = props.variant or "default";
    className = props.className or "";

    variant_class = "alert-destructive "
        if variant == "destructive"
        else "alert-default ";

    return (
        <div
            data-slot="alert"
            role="alert"
            className={"alert-container " + variant_class + className}
        >
            {(<div className="alert-title">{title}</div>) if title else None}{(
                <div className="alert-description">{description}</div>
            )
                if description
                else None}{children}
        </div>
    );
}
