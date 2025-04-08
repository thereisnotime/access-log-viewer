import Vue from 'vue';
import Vuetify from 'vuetify/lib/framework';

Vue.use(Vuetify);

export default new Vuetify({
    theme: {
        dark: window.matchMedia('(prefers-color-scheme: dark)').matches,
        options: {
            customProperties: true,
        },
        themes: {
            dark: {
                primary: '#8B0000', // Dark red
                secondary: '#b71c1c',
                accent: '#e53935',
                error: '#ff5252',
                info: '#2196F3',
                success: '#4CAF50',
                warning: '#FB8C00',
                background: '#121212',
                surface: '#1E1E1E',
            },
            light: {
                primary: '#8B0000', // Dark red
                secondary: '#b71c1c',
                accent: '#e53935',
                error: '#FF5252',
                info: '#2196F3',
                success: '#4CAF50',
                warning: '#FB8C00',
                background: '#F5F5F5',
                surface: '#FFFFFF',
            }
        }
    },
});
