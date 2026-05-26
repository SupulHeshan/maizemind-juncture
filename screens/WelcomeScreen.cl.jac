"""Welcome Screen"""

import from "@jac/runtime" { jacSignup, jacLogin, useNavigate }
import from react { useContext }
import from "lucide-react" { Brain, Lightbulb, TrendingUp, ArrowRight, Play, GitBranch, Quote, BookOpen, GraduationCap, Sparkles, ChevronDown }
import from ..screens.AppContext { getAppContext }
import from ..components.Button { Button }
import from ..components.Tabs { Tabs, TabsContent, TabsList, TabsTrigger }
import from ..components.Modal { Modal }
import from ..components.EulaContent { getEulaContent }

def:pub WelcomeScreen(props: any) -> JsxElement {
    nav = useNavigate();
    _AppCtx = getAppContext();
    ctx = useContext(_AppCtx);

    has isSignup: bool = False,
        name: str = "",
        email: str = "",
        password: str = "",
        error: str = "",
        loading: bool = False,
        showEulaModal: bool = False,
        eulaAccepted: bool = False,
        pendingAction: str = "",
        videoStarted: bool = False;

    def openEulaForSignup() -> None {
        error = "";
        # Basic field validation before even opening the modal
        if email == "" or password == "" { error = "Please fill in all fields"; return; }
        eulaAccepted = False;
        pendingAction = "signup";
        showEulaModal = True;
    }

    def openEulaForGuest() -> None {
        eulaAccepted = False;
        pendingAction = "guest";
        showEulaModal = True;
    }

    def closeEulaModal() -> None {
        showEulaModal = False;
        eulaAccepted = False;
        pendingAction = "";
    }

    async def handleEulaContinue() -> None {
        showEulaModal = False;
        if pendingAction == "signup" {
            await handleSignup();
        } elif pendingAction == "guest" {
            await handleContinueAsGuest();
        }
        pendingAction = "";
        eulaAccepted = False;
    }

    async def handleSignup() -> None {
        error = "";
        if email == "" or password == "" { error = "Please fill in all fields"; return; }

        at_idx = email.find("@");
        if at_idx <= 0 or at_idx == len(email) - 1 {
            error = "Please enter a valid email address.";
            return;
        }
        domain = email[at_idx + 1:];
        if "." not in domain or domain.startswith(".") or domain.endswith(".") {
            error = "Please enter a valid email address.";
            return;
        }

        loading = True;

        try {
            existing_result = await root spawn GetUserByEmail(email=email);
            existing_user = existing_result["reports"][0] if existing_result["reports"] else None;
            if existing_user and "id" in existing_user {
                error = "An account with this email already exists. Please log in instead.";
                loading = False;
                return;
            }
        } except Exception {}

        signup_result = await jacSignup(email, password);
        if not signup_result["success"] {
            error = signup_result["error"] if "error" in signup_result else "Signup failed";
            loading = False;
            return;
        }

        login_success = await jacLogin(email, password);
        if not login_success {
            error = "Account created but login failed. Please sign in.";
            loading = False;
            return;
        }

        userId = "";
        try {
            result = await root spawn CreateUser(
                name=name if name else email.split("@")[0],
                email=email,
                isGuest=False
            );
            user_data = result["reports"][0] if result["reports"] else {};
            if "error" in user_data and user_data["error"] == "account_exists" {
                error = "An account with this email already exists. Please log in instead.";
                loading = False;
                return;
            }
            userId = user_data["id"] if "id" in user_data else "";
        } except Exception {}

        loading = False;
        saved_email = email;
        email = "";
        password = "";
        name = "";
        ctx.setAuth(userId, saved_email, False);
        nav("/generate");
    }

    async def handleLogin() -> None {
        error = "";
        if email == "" or password == "" { error = "Please fill in all fields"; return; }
        loading = True;

        success = await jacLogin(email, password);
        if not success {
            error = "Invalid email or password";
            loading = False;
            return;
        }

        saved_email = email;
        email = "";
        password = "";

        try {
            result = await root spawn GetUserByEmail(email=saved_email);
            user_data = result["reports"][0] if result["reports"] else {};
            if user_data and "id" in user_data {
                is_dark = "theme" in user_data and user_data["theme"] == "dark";
                ctx.setAuth(user_data["id"], saved_email, is_dark);
            }
        } except Exception {}

        loading = False;
        nav("/generate");
    }

    async def handleContinueAsGuest() -> None {
        nav("/generate");
    }

    def handleTabChange(v: str) -> None {
        isSignup = (v == "signup");
        error = "";
    }

    has showEulaViewOnly: bool = False;

    def openEulaReadOnly() -> None {
        showEulaViewOnly = True;
    }

    def closeEulaReadOnly() -> None {
        showEulaViewOnly = False;
    }

    def startDemoVideo() -> None {
        videoStarted = True;
        v = document.querySelector(".lp-video");
        if v { v.play(); }
    }

    activeTab = "signup" if isSignup else "login";

    return (
        <>
            {(
                <Modal
                    title="END USER LICENSE AGREEMENT (EULA)"
                    content={getEulaContent()}
                    checkboxLabel="I have read and agree to the End User License Agreement"
                    isChecked={eulaAccepted}
                    onCheckboxChange={lambda checked -> None { eulaAccepted = checked; }}
                    primaryButton={{
                        "label": "Continue",
                        "onClick": handleEulaContinue,
                        "disabled": not eulaAccepted
                    }}
                    secondaryButton={{
                        "label": "Back",
                        "onClick": closeEulaModal
                    }}
                    onClose={closeEulaModal}
                    showClose={True}
                    closeable={True}
                />
            ) if showEulaModal else None}

            {(
                <Modal
                    title="End User License Agreement"
                    content={getEulaContent()}
                    primaryButton={{
                        "label": "Close",
                        "onClick": closeEulaReadOnly
                    }}
                    onClose={closeEulaReadOnly}
                    showClose={True}
                    closeable={True}
                />
            ) if showEulaViewOnly else None}

            <div className="lp-nav">
                <div className="lp-nav-inner">
                    <a href="#top" className="lp-nav-logo">MaizeMind</a>
                    <div className="lp-nav-links">
                        <a href="#how" className="lp-nav-link">How it works</a>
                        <a href="#demo" className="lp-nav-link">Demo</a>
                        <a href="#behind" className="lp-nav-link">Behind the scenes</a>
                        <a href="#why" className="lp-nav-link">Why MaizeMind</a>
                    </div>
                    <a href="#auth-section" className="lp-nav-cta">Sign in</a>
                </div>
            </div>

            <div className="lp-hero" id="top">
                <div className="lp-hero-bg"></div>
                <div className="lp-hero-inner">
                    <div className="lp-hero-badge">
                        <Sparkles />
                        <span>A student project from U-M · Spring 2026</span>
                    </div>
                    <h1 className="lp-hero-title">
                        Notes in.
                        <span className="lp-hero-title-accent"> Argument out.</span>
                    </h1>
                    <p className="lp-hero-subtitle">
                        Paste in messy notes, and watch as MaizeMind maps your arguments into a graph, and helps you find and fix the weak parts.
                    </p>
                    <div className="lp-hero-ctas">
                        <button className="lp-hero-cta-primary" onClick={openEulaForGuest} disabled={loading}>
                            <span>Try it free</span>
                            <ArrowRight />
                        </button>
                        <a href="#demo" className="lp-hero-cta-secondary">
                            <Play />
                            <span>Watch the demo</span>
                        </a>
                    </div>
                    <div className="lp-hero-cycler" aria-hidden="true">
                        <div className="lp-hero-cycler-label">MaizeMind helps you interrogate any argument</div>
                        <div className="lp-hero-cycler-stage">
                            <div className="lp-hero-cycler-card lp-hero-cycler-card-1">
                                <div className="lp-cycler-head">
                                    <span className="lp-cycler-type">Thesis</span>
                                    <span className="lp-cycler-score">82</span>
                                </div>
                                <div className="lp-cycler-text">Wisdom comes from questioning, not from certainty.</div>
                                <div className="lp-cycler-note">Is questioning the source of wisdom, or just a prerequisite?</div>
                            </div>
                            <div className="lp-hero-cycler-card lp-hero-cycler-card-2">
                                <div className="lp-cycler-head">
                                    <span className="lp-cycler-type">Thesis</span>
                                    <span className="lp-cycler-score">68</span>
                                </div>
                                <div className="lp-cycler-text">Voting should be mandatory in democracies.</div>
                                <div className="lp-cycler-note">What about citizens who refuse to vote as political expression?</div>
                            </div>
                            <div className="lp-hero-cycler-card lp-hero-cycler-card-3">
                                <div className="lp-cycler-head">
                                    <span className="lp-cycler-type">Thesis</span>
                                    <span className="lp-cycler-score">71</span>
                                </div>
                                <div className="lp-cycler-text">Social media has eroded public discourse.</div>
                                <div className="lp-cycler-note">Compared to what historical baseline?</div>
                            </div>
                            <div className="lp-hero-cycler-card lp-hero-cycler-card-4">
                                <div className="lp-cycler-head">
                                    <span className="lp-cycler-type">Thesis</span>
                                    <span className="lp-cycler-score">64</span>
                                </div>
                                <div className="lp-cycler-text">Standardized testing fails to measure real capability.</div>
                                <div className="lp-cycler-note">How would you define "real capability"?</div>
                            </div>
                        </div>
                    </div>
                </div>
                <a href="#how" className="lp-scroll-indicator">
                    <ChevronDown />
                </a>
            </div>

            <div className="lp-section lp-howitworks" id="how">
                <div className="lp-section-inner">
                    <div className="lp-section-label">How it works</div>
                    <h2 className="lp-section-heading">From notes to argument, in three steps.</h2>

                    <div className="lp-flow">
                        <div className="lp-flow-step">
                            <div className="lp-flow-number">01</div>
                            <div className="lp-flow-mock lp-flow-mock-notes">
                                <div className="lp-flow-mock-label">your notes</div>
                                <div className="lp-flow-mock-text">
                                    Socrates said wisdom starts with knowing you don't know. But then how do we ever act? Plato's Apology shows him still defending a position...
                                </div>
                            </div>
                            <div className="lp-flow-title">Paste anything</div>
                        </div>

                        <div className="lp-flow-arrow" aria-hidden="true">
                            <svg viewBox="0 0 60 24" fill="none">
                                <path d="M 4 12 L 52 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M 46 6 L 54 12 L 46 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                            </svg>
                        </div>

                        <div className="lp-flow-step">
                            <div className="lp-flow-number">02</div>
                            <div className="lp-flow-mock lp-flow-mock-graph">
                                <div className="lp-flow-mini-thesis"></div>
                                <svg className="lp-flow-mini-svg" viewBox="0 0 120 60" preserveAspectRatio="none">
                                    <line x1="32" y1="22" x2="60" y2="6" stroke="#10b981" strokeWidth="1.6" />
                                    <line x1="88" y1="22" x2="60" y2="6" stroke="#ef4444" strokeWidth="1.6" strokeDasharray="3 2" />
                                </svg>
                                <div className="lp-flow-mini-row">
                                    <div className="lp-flow-mini-claim"></div>
                                    <div className="lp-flow-mini-counter"></div>
                                </div>
                            </div>
                            <div className="lp-flow-title">Get the graph</div>
                        </div>

                        <div className="lp-flow-arrow" aria-hidden="true">
                            <svg viewBox="0 0 60 24" fill="none">
                                <path d="M 4 12 L 52 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
                                <path d="M 46 6 L 54 12 L 46 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                            </svg>
                        </div>

                        <div className="lp-flow-step">
                            <div className="lp-flow-number">03</div>
                            <div className="lp-flow-mock lp-flow-mock-score">
                                <div className="lp-flow-score-row">
                                    <span className="lp-flow-score-old">52</span>
                                    <span className="lp-flow-score-arrow">→</span>
                                    <span className="lp-flow-score-new">81</span>
                                </div>
                                <div className="lp-flow-score-label">Reasoning Score</div>
                                <div className="lp-flow-score-bar">
                                    <div className="lp-flow-score-fill"></div>
                                </div>
                            </div>
                            <div className="lp-flow-title">Strengthen it</div>
                        </div>
                    </div>

                    <p className="lp-flow-caption">
                        Add counterarguments, cite a Wikipedia source, or answer a hidden assumption. Your reasoning score climbs as you refine your work.
                    </p>
                </div>
            </div>

            <div className="lp-section lp-video-section" id="demo">
                <div className="lp-section-inner">
                    <div className="lp-section-label">Demo</div>
                    <h2 className="lp-section-heading">See it in action.</h2>
                    <p className="lp-section-subhead">A short walkthrough of MaizeMind with real notes.</p>
                    <div className="lp-video-container">
                        <video
                            className="lp-video"
                            controls
                            playsInline
                            preload="metadata"
                            poster="/demo-thumbnail.png"
                            src="/demo.mp4"
                            onPlay={lambda -> None { videoStarted = True; }}>
                            Your browser doesn't support embedded video.
                        </video>
                        {(
                            <button
                                className="lp-video-play-btn"
                                onClick={startDemoVideo}
                                aria-label="Play demo video">
                                <Play />
                            </button>
                        ) if not videoStarted else None}
                    </div>
                </div>
            </div>

            <div className="lp-showcase" id="behind">
                <div className="lp-section-inner">
                    <div className="lp-section-label">Behind the scenes</div>
                    <h2 className="lp-section-heading">Every node gets its own score and its own scrutiny.</h2>
                    <p className="lp-section-subhead">Each node discerns the assumptions it's resting on, and the most useful actions to take next.</p>
                </div>
                <div className="lp-showcase-frame">
                    <div className="lp-showcase-window">
                        <div className="lp-showcase-titlebar">
                            <span className="lp-showcase-dot lp-showcase-dot-r"></span>
                            <span className="lp-showcase-dot lp-showcase-dot-y"></span>
                            <span className="lp-showcase-dot lp-showcase-dot-g"></span>
                            <span className="lp-showcase-title">maizemind.com / review</span>
                        </div>
                        <div className="lp-showcase-body">
                            <div className="lp-showcase-canvas">
                                <div className="lp-showcase-graph">
                                    <div className="lp-mock-node lp-mock-thesis lp-showcase-node-pos-1">
                                        <div className="lp-mock-tag">THESIS · 82</div>
                                        <div className="lp-mock-text">Wisdom comes from questioning.</div>
                                    </div>
                                    <div className="lp-mock-node lp-mock-claim lp-showcase-node-pos-2 lp-showcase-node-selected">
                                        <div className="lp-mock-tag">CLAIM · 75</div>
                                        <div className="lp-mock-text">Socrates argued ignorance is the start of knowledge.</div>
                                    </div>
                                    <div className="lp-mock-node lp-mock-evidence lp-showcase-node-pos-3">
                                        <div className="lp-mock-tag">EVIDENCE · 88</div>
                                        <div className="lp-mock-text">Plato, Apology, 399 BCE.</div>
                                    </div>
                                    <div className="lp-mock-node lp-mock-counter lp-showcase-node-pos-4">
                                        <div className="lp-mock-tag">COUNTER · 60</div>
                                        <div className="lp-mock-text">But certainty drives action.</div>
                                    </div>
                                </div>
                            </div>
                            <div className="lp-showcase-panel">
                                <div className="lp-panel-header">
                                    <span className="lp-panel-tag">CLAIM</span>
                                    <span className="lp-panel-score">75</span>
                                </div>
                                <div className="lp-panel-section">
                                    <div className="lp-panel-section-title">Issues found</div>
                                    <div className="lp-panel-issue">
                                        <span className="lp-panel-bullet"></span>
                                        <span>Needs more direct support</span>
                                    </div>
                                </div>
                                <div className="lp-panel-section">
                                    <div className="lp-panel-section-title">Quick actions</div>
                                    <div className="lp-panel-actions">
                                        <span className="lp-panel-btn lp-panel-btn-primary">Respond</span>
                                        <span className="lp-panel-btn">Counter</span>
                                        <span className="lp-panel-btn">Expand</span>
                                        <span className="lp-panel-btn">Investigate</span>
                                    </div>
                                </div>
                                <div className="lp-panel-section">
                                    <div className="lp-panel-section-title">Hidden assumption</div>
                                    <div className="lp-panel-assumption">Is ignorance the only path to knowledge?</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="lp-section lp-section-light lp-why" id="why">
                <div className="lp-section-inner">
                    <div className="lp-section-label">Why MaizeMind</div>
                    <h2 className="lp-section-heading">An AI that argues with you.</h2>
                    <p className="lp-section-subhead">Most AI tools write your argument for you. We wanted one that helps you write a better one.</p>
                    <div className="lp-why-grid">
                        <div className="lp-why-card lp-why-card-blue">
                            <div className="lp-why-icon"><GitBranch /></div>
                            <h3 className="lp-why-title">Visual reasoning</h3>
                            <p className="lp-why-desc">Your argument is displayed as a graph. Weak claims and missing supports are visible at a glance.</p>
                        </div>
                        <div className="lp-why-card lp-why-card-purple">
                            <div className="lp-why-icon"><Quote /></div>
                            <h3 className="lp-why-title">Critique, not creation</h3>
                            <p className="lp-why-desc">Surface the counterarguments, hidden assumptions, and questions a sharp reader would ask.</p>
                        </div>
                        <div className="lp-why-card lp-why-card-green">
                            <div className="lp-why-icon"><BookOpen /></div>
                            <h3 className="lp-why-title">Real sources</h3>
                            <p className="lp-why-desc">Wikipedia sources with the relevant passages highlighted, so you can verify the citation yourself.</p>
                        </div>
                        <div className="lp-why-card lp-why-card-amber">
                            <div className="lp-why-icon"><GraduationCap /></div>
                            <h3 className="lp-why-title">Built at Michigan</h3>
                            <p className="lp-why-desc">An EECS 449 senior project, built by students who believe AI can work productively to assist your critical reasoning.</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="lp-quote">
                <div className="lp-quote-inner">
                    <div className="lp-quote-mark">"</div>
                    <p className="lp-quote-text">
                        <span className="lp-quote-line">AI shouldn't do your thinking,</span>
                        <span className="lp-quote-line lp-quote-line-em">it should sharpen it.</span>
                    </p>
                </div>
            </div>

            <div className="lp-section lp-getstarted" id="auth-section">
                <div className="lp-getstarted-inner">
                    <div className="lp-getstarted-text">
                        <div className="lp-section-label">Get started</div>
                        <h2 className="lp-getstarted-heading">Try it on something you're working on.</h2>
                        <p className="lp-getstarted-sub">Free! Guest mode works without an account.</p>
                        <ul className="lp-getstarted-bullets">
                            <li><Brain /><span>Works with notes, outlines, or half-baked ideas</span></li>
                            <li><Lightbulb /><span>Instant critique, counterarguments, hidden assumptions</span></li>
                            <li><TrendingUp /><span>Live quality scores as you sharpen your reasoning</span></li>
                        </ul>
                    </div>
                    <div className="auth-container">
                        <div className="auth-card">
                            <div className="auth-header">
                                <h4>Sign in</h4>
                                <p>Or jump in as a guest below.</p>
                            </div>
                            <Tabs value={activeTab} onValueChange={handleTabChange} className="auth-tabs">
                                <TabsList className="auth-tabs-list">
                                    <TabsTrigger value="login" activeValue={activeTab} onValueChange={handleTabChange} className="auth-tab-trigger">
                                        Login
                                    </TabsTrigger>
                                    <TabsTrigger value="signup" activeValue={activeTab} onValueChange={handleTabChange} className="auth-tab-trigger">
                                        Sign Up
                                    </TabsTrigger>
                                </TabsList>

                                <TabsContent value="login" activeValue={activeTab} className="auth-tab-content">
                                    {(<div className="auth-error">{error}</div>) if error else None}
                                    <div className="form-field">
                                        <label className="form-label">Email</label>
                                        <input
                                            type="text"
                                            placeholder="you@example.com"
                                            value={email}
                                            onChange={lambda e -> None { email = e.target.value; }}
                                            className="auth-input"
                                        />
                                    </div>
                                    <div className="form-field">
                                        <label className="form-label">Password</label>
                                        <input
                                            type="password"
                                            value={password}
                                            onChange={lambda e -> None { password = e.target.value; }}
                                            className="auth-input"
                                        />
                                    </div>
                                    <Button label={"Processing..." if loading else "Login"} onClick={handleLogin} className="auth-submit-btn" />
                                </TabsContent>

                                <TabsContent value="signup" activeValue={activeTab} className="auth-tab-content">
                                    {(<div className="auth-error">{error}</div>) if error and isSignup else None}
                                    <div className="form-field">
                                        <label className="form-label">Name</label>
                                        <input
                                            type="text"
                                            placeholder="Your name"
                                            value={name}
                                            onChange={lambda e -> None { name = e.target.value; }}
                                            className="auth-input"
                                        />
                                    </div>
                                    <div className="form-field">
                                        <label className="form-label">Email</label>
                                        <input
                                            type="text"
                                            placeholder="you@example.com"
                                            value={email}
                                            onChange={lambda e -> None { email = e.target.value; }}
                                            className="auth-input"
                                        />
                                    </div>
                                    <div className="form-field">
                                        <label className="form-label">Password</label>
                                        <input
                                            type="password"
                                            value={password}
                                            onChange={lambda e -> None { password = e.target.value; }}
                                            className="auth-input"
                                        />
                                    </div>
                                    <Button label={"Processing..." if loading else "Create Account"} onClick={openEulaForSignup} disabled={loading} className="auth-submit-btn" />
                                </TabsContent>
                            </Tabs>

                            <div className="auth-divider">OR</div>
                            <Button label={"Processing..." if loading else "Continue as Guest"} variant="outline" onClick={openEulaForGuest} disabled={loading} className="auth-guest-btn" />

                            <div className="auth-terms-row">
                                <span className="auth-terms-text">By continuing, you agree to our </span>
                                <button className="auth-terms-link" onClick={openEulaReadOnly}>
                                    End User License Agreement
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="lp-fromteam">
                <div className="lp-fromteam-inner">
                    <div className="lp-fromteam-label">P.S.</div>
                    <p className="lp-fromteam-text">
                        MaizeMind is still a work in progress! If you find something weird,<a href="mailto:himaya@umich.edu" className="lp-fromteam-link"> tell us</a>.
                    </p>
                </div>
            </div>

            <div className="lp-footer">
                <div className="lp-footer-inner">
                    <div className="lp-footer-attribution">
                        <div>University of Michigan · EECS 449</div>
                        <div className="lp-footer-attribution-sub">
                            <a
                                className="built-with-jaseci"
                                href="https://jaseci.org"
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                <span>Built with </span>
                                <img
                                    src="https://www.jaseci.org/_next/image?url=%2Fimages%2Flogo.png&w=128&q=75"
                                    alt="Jaseci logo"
                                    className="built-with-jaseci-logo"
                                />
                                <span className="built-with-jaseci-wordmark">JASECI</span>
                            </a>
                            <span> · © 2026 MaizeMind</span>
                        </div>
                    </div>
                    <div className="lp-footer-links">
                        <button className="lp-footer-link" onClick={openEulaReadOnly}>End User License Agreement</button>
                        <a className="lp-footer-link" href="mailto:himaya@umich.edu">Contact</a>
                    </div>
                </div>
            </div>
        </>
    );
}
