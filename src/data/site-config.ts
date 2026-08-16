import avatar from '../assets/images/avatar.jpg';
import hero from '../assets/images/hero.jpg';
import type { SiteConfig } from '../types';

const siteConfig: SiteConfig = {
    website: 'https://sramost.github.io',

    // ========== DATOS PERSONALES ==========
    avatar: {
        src: avatar,
        alt: 'Foto de Santiago Ramos'
    },
    title: 'Santiago Ramos',
    subtitle: 'Estudiante de Ingeniería de Sistemas',
    description: 'Portafolio personal de Santiago Ramos - Estudiante de Bases de Datos 2',

    image: {
        src: '/dante-preview.jpg',
        alt: 'Santiago Ramos - Portafolio'
    },

    // ========== MENÚ DE NAVEGACIÓN ==========
    headerNavLinks: [
        {
            text: 'Home',
            href: '/'
        },
        {
            text: 'Evidencias',
            href: '/evidencias'
        }
    ],

    // ========== PIE DE PÁGINA ==========
    footerNavLinks: [
        {
            text: 'Inicio',
            href: '/'
        },
        {
            text: 'Evidencias',
            href: '/evidencias'
        }
    ],

    // ========== REDES SOCIALES ==========
    socialLinks: [
        {
            text: 'GitHub',
            href: 'https://github.com/sramost'
        },
        {
            text: 'Instagram',
            href: 'https://instagram.com/sramos.t'
        },

    ],

    // ========== SECCIÓN PRINCIPAL (HOME) ==========
    hero: {
        title: '¡Hola! Soy Santiago Ramos',
        text: `Soy estudiante de **Ingeniería de Sistemas** y este es mi portafolio para la materia de **Bases de Datos 2**.

---

### 🎥 Video de presentación

<iframe width="100%" height="400" src="https://youtu.be/9umR8jGgidQ" frameborder="0" allowfullscreen style="border-radius:12px; margin: 1rem 0;"></iframe>

---

### 📋 Información General

**Nombre:** Santiago Ramos Trejos

**Gustos:** Me encantan las actividades donde mi mente siente que no se está esforzando, aunque sí lo esté haciendo. Por ejemplo, en relación a los deportes, me gusta tanto ver como practicar fútbol, voleibol y, en especial, ping pong. Me gusta un montón los videojuegos, especialmente los competitivos por ejemplo he invertido mucho tiempo en Fortnite y llegué a 100k copas en Brawl Stars 😹 . También disfruto pasar tiempo con mi familia, pareja y amigos. Y aunque solía tocar el trombón en una banda sinfónica, hoy mis intereses musicales se limitan a escuchar.

---

### 🗄️ ¿Por qué Bases de Datos 2?

Porque las bases de datos son el **corazón de cualquier sistema de información**. Entender cómo se organizan, consultan y optimizan los datos no solo es fundamental para un ingeniero de sistemas, sino que abre las puertas a entender el mundo digital que nos rodea. Esta materia me permite conectar la teoría con la práctica y prepararme para los retos del mundo real.

---

### 📚 Este semestre

Espero poder demostrar el conocimiento tanto **teórico como práctico** de este amplio mundo de las bases de datos, y aplicar lo aprendido en proyectos que realmente tengan impacto.`,
        image: {
            src: hero,
            alt: 'Santiago Ramos - Estudiante de Ingeniería de Sistemas'
        },
        actions: [
            {
                text: 'Ver evidencias',
                href: '/evidencias'
            }
        ]
    },

    // ========== SUSCRIPCIÓN (desactivada) ==========
    subscribe: {
        enabled: false,
        title: '',
        text: '',
        form: {
            action: '#'
        }
    },

    postsPerPage: 8,
    projectsPerPage: 8
};

export default siteConfig;
