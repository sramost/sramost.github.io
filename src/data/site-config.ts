import avatar from '../assets/images/avatar.jpg';
import hero from '../assets/images/hero.jpg';
import type { SiteConfig } from '../types';

const siteConfig: SiteConfig = {
    website: 'https://sramost.github.io',

    // Foto de perfil (circular, se usará en el header o sidebar)
    avatar: {
        src: avatar,
        alt: 'Foto de Santiago Ramos'
    },

    // Títulos principales
    title: 'Santiago Ramos',
    subtitle: 'Estudiante de Ingeniería de Sistemas',
    description: 'Portafolio personal para la materia Bases de Datos 2',

    // Imagen para redes sociales (cuando compartas el enlace)
    image: {
        src: '/dante-preview.jpg',  // Puedes cambiar esta imagen después
        alt: 'Portafolio Santiago Ramos'
    },

    // 📌 Menú de navegación (SOLO Home y Evidencias)
    headerNavLinks: [
        {
            text: 'Home',
            href: '/'
        },
        {
            text: 'Evidencias',
            href: '/evidencias'   // 👈 Esta página la crearás después
        }
    ],

    // Enlaces del pie de página (los puedes eliminar o dejar solo los que uses)
    footerNavLinks: [
        {
            text: 'GitHub',
            href: 'https://github.com/sramost'  // 👈 Pon tu perfil de GitHub
        },
        {
            text: 'LinkedIn',
            href: 'https://linkedin.com/in/tu-perfil'  // 👈 Pon tu LinkedIn si tienes
        }
    ],

    // Redes sociales (puedes dejarlas o eliminarlas)
    socialLinks: [
        {
            text: 'GitHub',
            href: 'https://github.com/sramost'
        },
        {
            text: 'Instagram',
            href: 'https://instagram.com/tu-usuario'  // 👈 Cambia por tu usuario
        }
    ],

    // 🏠 SECCIÓN PRINCIPAL (HERO) - Aquí va tu video y presentación
    hero: {
        title: '¡Hola! Soy Santiago Ramos',
        text: `
Soy estudiante de **Ingeniería de Sistemas** y actualmente curso la materia **Bases de Datos 2**. 

### Video de presentación

<iframe width="100%" height="400" src="https://www.youtube.com/embed/TU_ID_VIDEO" title="Video presentación" frameborder="0" allowfullscreen></iframe>

---

### Información General

- **Nombre:** Santiago Ramos Trejos
- **Gustos:** Me encanta el deporte, especialmente fútbol, voleibol y ping pong. Soy un apasionado de los videojuegos competitivos (muchas horas en Fortnite y 100k copas en Brawl Stars). Disfruto pasar tiempo con mi familia, pareja y amigos. También me gusta la música; toqué el trombón en una banda sinfónica, aunque ahora solo la disfruto como oyente.

### ¿Por qué Bases de Datos 2?

Porque es el corazón de cualquier sistema de información. Entender cómo se organizan, consultan y optimizan los datos me permite no solo aprobar la materia, sino también construir aplicaciones más robustas y eficientes. Además, me apasiona el reto de transformar datos en información valiosa para la toma de decisiones.

### Este semestre

Espero poder demostrar tanto el conocimiento teórico como práctico de este amplio mundo de las bases de datos, aplicando lo aprendido en proyectos reales y enfrentando desafíos que me preparen para el mundo laboral.
        `,
        image: {
            src: hero,   // Esta imagen ya no se usará porque pusiste video, pero déjala por si acaso
            alt: 'Santiago Ramos'
        },
        actions: [
            {
                text: 'Ver Evidencias',
                href: '/evidencias'
            }
        ]
    },

    // Sección de suscripción (puedes desactivarla si no la usas)
    subscribe: {
        enabled: false,   // 👈 Cambia a false para ocultarla
        title: 'Subscribe to Dante Newsletter',
        text: 'One update per week. All the latest posts directly in your inbox.',
        form: {
            action: '#'
        }
    },

    postsPerPage: 8,
    projectsPerPage: 8
};

export default siteConfig;
