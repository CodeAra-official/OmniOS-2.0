/*
 * OmniOS 2.0 Setup Application
 * Initial system configuration wizard
 */

#include "omnios.h"
#include "ui/ui_framework.h"
#include "security/security.h"
#include "drivers/wifi_driver.h"

typedef enum {
    SETUP_STEP_WELCOME = 0,
    SETUP_STEP_LANGUAGE,
    SETUP_STEP_TIMEZONE,
    SETUP_STEP_USER_ACCOUNT,
    SETUP_STEP_WIFI,
    SETUP_STEP_DISPLAY,
    SETUP_STEP_COMPLETE,
    SETUP_STEP_COUNT
} setup_step_t;

typedef struct {
    char language[32];
    char timezone[64];
    char username[32];
    char password[64];
    char wifi_ssid[64];
    char wifi_password[64];
    int display_brightness;
    bool setup_complete;
} setup_config_t;

static setup_config_t g_setup_config;
static setup_step_t g_current_step = SETUP_STEP_WELCOME;
static ui_window_t* g_setup_window;

// Function prototypes
void setup_application_main(void);
void setup_init_ui(void);
void setup_show_step(setup_step_t step);
void setup_handle_input(ui_event_t* event);
void setup_save_configuration(void);

// Step handlers
void setup_step_welcome(void);
void setup_step_language(void);
void setup_step_timezone(void);
void setup_step_user_account(void);
void setup_step_wifi(void);
void setup_step_display(void);
void setup_step_complete(void);

void setup_application_main(void) {
    // Initialize setup configuration
    memset(&g_setup_config, 0, sizeof(setup_config_t));
    
    // Set defaults
    strcpy(g_setup_config.language, "English");
    strcpy(g_setup_config.timezone, "UTC");
    g_setup_config.display_brightness = 75;
    
    // Initialize UI
    setup_init_ui();
    
    // Show welcome step
    setup_show_step(SETUP_STEP_WELCOME);
    
    // Main event loop
    ui_event_t event;
    while (!g_setup_config.setup_complete) {
        if (ui_get_event(&event)) {
            setup_handle_input(&event);
        }
        ui_update();
    }
    
    // Save configuration and exit
    setup_save_configuration();
    ui_destroy_window(g_setup_window);
}

void setup_init_ui(void) {
    // Create main setup window
    g_setup_window = ui_create_window("OmniOS 2.0 Setup", 10, 5, 60, 15);
    ui_set_window_color(g_setup_window, UI_COLOR_BLUE, UI_COLOR_WHITE);
    ui_show_window(g_setup_window);
}

void setup_show_step(setup_step_t step) {
    g_current_step = step;
    
    // Clear window content
    ui_clear_window(g_setup_window);
    
    // Show step-specific content
    switch (step) {
        case SETUP_STEP_WELCOME:
            setup_step_welcome();
            break;
        case SETUP_STEP_LANGUAGE:
            setup_step_language();
            break;
        case SETUP_STEP_TIMEZONE:
            setup_step_timezone();
            break;
        case SETUP_STEP_USER_ACCOUNT:
            setup_step_user_account();
            break;
        case SETUP_STEP_WIFI:
            setup_step_wifi();
            break;
        case SETUP_STEP_DISPLAY:
            setup_step_display();
            break;
        case SETUP_STEP_COMPLETE:
            setup_step_complete();
            break;
        default:
            break;
    }
    
    ui_refresh_window(g_setup_window);
}

void setup_step_welcome(void) {
    ui_draw_text(g_setup_window, 2, 2, "Welcome to OmniOS 2.0!", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "This setup wizard will help you configure");
    ui_draw_text(g_setup_window, 2, 5, "your system for first use.");
    ui_draw_text(g_setup_window, 2, 7, "Features to configure:");
    ui_draw_text(g_setup_window, 4, 8, "• Language and Region");
    ui_draw_text(g_setup_window, 4, 9, "• User Account");
    ui_draw_text(g_setup_window, 4, 10, "• Network Settings");
    ui_draw_text(g_setup_window, 4, 11, "• Display Settings");
    
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_language(void) {
    ui_draw_text(g_setup_window, 2, 2, "Language Selection", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "Select your preferred language:");
    
    // Language options
    const char* languages[] = {
        "English", "Spanish", "French", "German", "Chinese", "Japanese"
    };
    
    for (int i = 0; i < 6; i++) {
        bool selected = (strcmp(g_setup_config.language, languages[i]) == 0);
        ui_draw_radio_button(g_setup_window, 4, 6 + i, languages[i], selected);
    }
    
    ui_draw_button(g_setup_window, 35, 13, "< Back", false);
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_timezone(void) {
    ui_draw_text(g_setup_window, 2, 2, "Timezone Selection", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "Select your timezone:");
    
    // Timezone options
    const char* timezones[] = {
        "UTC (GMT+0)", "EST (GMT-5)", "PST (GMT-8)", 
        "CET (GMT+1)", "JST (GMT+9)", "AEST (GMT+10)"
    };
    
    for (int i = 0; i < 6; i++) {
        bool selected = (strstr(g_setup_config.timezone, timezones[i]) != NULL);
        ui_draw_radio_button(g_setup_window, 4, 6 + i, timezones[i], selected);
    }
    
    ui_draw_button(g_setup_window, 35, 13, "< Back", false);
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_user_account(void) {
    ui_draw_text(g_setup_window, 2, 2, "User Account Setup", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "Create your user account:");
    
    ui_draw_text(g_setup_window, 2, 6, "Username:");
    ui_draw_textbox(g_setup_window, 12, 6, 20, g_setup_config.username);
    
    ui_draw_text(g_setup_window, 2, 8, "Password:");
    ui_draw_textbox(g_setup_window, 12, 8, 20, "********"); // Masked
    
    ui_draw_text(g_setup_window, 2, 10, "Confirm:");
    ui_draw_textbox(g_setup_window, 12, 10, 20, "********"); // Masked
    
    ui_draw_text(g_setup_window, 2, 12, "Password requirements:");
    ui_draw_text(g_setup_window, 4, 13, "• At least 8 characters");
    ui_draw_text(g_setup_window, 4, 14, "• Mix of letters and numbers");
    
    ui_draw_button(g_setup_window, 35, 13, "< Back", false);
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_wifi(void) {
    ui_draw_text(g_setup_window, 2, 2, "WiFi Configuration", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "Configure network connection:");
    
    // Scan for networks
    wifi_network_t networks[8];
    int network_count = wifi_scan_networks(networks, 8);
    
    if (network_count > 0) {
        ui_draw_text(g_setup_window, 2, 6, "Available networks:");
        
        for (int i = 0; i < network_count && i < 6; i++) {
            char network_info[64];
            snprintf(network_info, sizeof(network_info), "%s (%d%%)", 
                     networks[i].ssid, networks[i].signal_strength);
            
            bool selected = (strcmp(g_setup_config.wifi_ssid, networks[i].ssid) == 0);
            ui_draw_radio_button(g_setup_window, 4, 7 + i, network_info, selected);
        }
        
        if (strlen(g_setup_config.wifi_ssid) > 0) {
            ui_draw_text(g_setup_window, 2, 14, "Password:");
            ui_draw_textbox(g_setup_window, 12, 14, 20, "********");
        }
    } else {
        ui_draw_text(g_setup_window, 2, 6, "No networks found", UI_COLOR_RED);
        ui_draw_button(g_setup_window, 2, 8, "Scan Again", false);
    }
    
    ui_draw_checkbox(g_setup_window, 2, 16, "Skip network setup", false);
    
    ui_draw_button(g_setup_window, 35, 13, "< Back", false);
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_display(void) {
    ui_draw_text(g_setup_window, 2, 2, "Display Settings", UI_COLOR_YELLOW);
    ui_draw_text(g_setup_window, 2, 4, "Configure display preferences:");
    
    ui_draw_text(g_setup_window, 2, 6, "Brightness:");
    ui_draw_slider(g_setup_window, 12, 6, 20, g_setup_config.display_brightness, 0, 100);
    
    char brightness_text[16];
    snprintf(brightness_text, sizeof(brightness_text), "%d%%", g_setup_config.display_brightness);
    ui_draw_text(g_setup_window, 34, 6, brightness_text);
    
    ui_draw_text(g_setup_window, 2, 8, "Color Scheme:");
    ui_draw_radio_button(g_setup_window, 4, 9, "Default (Blue)", true);
    ui_draw_radio_button(g_setup_window, 4, 10, "Dark Theme", false);
    ui_draw_radio_button(g_setup_window, 4, 11, "High Contrast", false);
    
    ui_draw_checkbox(g_setup_window, 2, 13, "Enable animations", true);
    ui_draw_checkbox(g_setup_window, 2, 14, "Show desktop icons", true);
    
    ui_draw_button(g_setup_window, 35, 13, "< Back", false);
    ui_draw_button(g_setup_window, 45, 13, "Next >", true);
}

void setup_step_complete(void) {
    ui_draw_text(g_setup_window, 2, 2, "Setup Complete!", UI_COLOR_GREEN);
    ui_draw_text(g_setup_window, 2, 4, "Your system has been configured successfully.");
    
    ui_draw_text(g_setup_window, 2, 6, "Configuration Summary:");
    ui_draw_text(g_setup_window, 4, 7, "Language: %s", g_setup_config.language);
    ui_draw_text(g_setup_window, 4, 8, "Timezone: %s", g_setup_config.timezone);
    ui_draw_text(g_setup_window, 4, 9, "Username: %s", g_setup_config.username);
    
    if (strlen(g_setup_config.wifi_ssid) > 0) {
        ui_draw_text(g_setup_window, 4, 10, "WiFi: %s", g_setup_config.wifi_ssid);
    } else {
        ui_draw_text(g_setup_window, 4, 10, "WiFi: Not configured");
    }
    
    ui_draw_text(g_setup_window, 4, 11, "Display: %d%% brightness", g_setup_config.display_brightness);
    
    ui_draw_text(g_setup_window, 2, 13, "Click Finish to start using OmniOS 2.0!");
    
    ui_draw_button(g_setup_window, 35, 15, "< Back", false);
    ui_draw_button(g_setup_window, 45, 15, "Finish", true);
}

void setup_handle_input(ui_event_t* event) {
    if (event->type == UI_EVENT_BUTTON_CLICK) {
        if (strcmp(event->data.button.text, "Next >") == 0 || 
            strcmp(event->data.button.text, "Finish") == 0) {
            
            if (g_current_step < SETUP_STEP_COMPLETE) {
                setup_show_step(g_current_step + 1);
            } else {
                g_setup_config.setup_complete = true;
            }
        } else if (strcmp(event->data.button.text, "< Back") == 0) {
            if (g_current_step > SETUP_STEP_WELCOME) {
                setup_show_step(g_current_step - 1);
            }
        }
    } else if (event->type == UI_EVENT_RADIO_BUTTON_SELECT) {
        // Handle radio button selections based on current step
        switch (g_current_step) {
            case SETUP_STEP_LANGUAGE:
                strcpy(g_setup_config.language, event->data.radio.text);
                break;
            case SETUP_STEP_TIMEZONE:
                strcpy(g_setup_config.timezone, event->data.radio.text);
                break;
            case SETUP_STEP_WIFI:
                // Extract SSID from network info
                char* space_pos = strchr(event->data.radio.text, ' ');
                if (space_pos) {
                    *space_pos = '\0';
                    strcpy(g_setup_config.wifi_ssid, event->data.radio.text);
                    *space_pos = ' ';
                }
                break;
            default:
                break;
        }
        setup_show_step(g_current_step); // Refresh display
    }
}

void setup_save_configuration(void) {
    // Create system configuration file
    FILE* config_file = fopen("/system/config/system.conf", "w");
    if (config_file) {
        fprintf(config_file, "[System]\n");
        fprintf(config_file, "language=%s\n", g_setup_config.language);
        fprintf(config_file, "timezone=%s\n", g_setup_config.timezone);
        fprintf(config_file, "setup_complete=true\n\n");
        
        fprintf(config_file, "[Display]\n");
        fprintf(config_file, "brightness=%d\n", g_setup_config.display_brightness);
        fprintf(config_file, "color_scheme=default\n\n");
        
        if (strlen(g_setup_config.wifi_ssid) > 0) {
            fprintf(config_file, "[Network]\n");
            fprintf(config_file, "wifi_ssid=%s\n", g_setup_config.wifi_ssid);
            fprintf(config_file, "wifi_enabled=true\n\n");
        }
        
        fclose(config_file);
    }
    
    // Create user account
    if (strlen(g_setup_config.username) > 0) {
        user_account_t account;
        strcpy(account.username, g_setup_config.username);
        strcpy(account.password_hash, g_setup_config.password); // Should be hashed
        account.uid = 1000;
        account.gid = 1000;
        account.privileges = USER_PRIVILEGE_STANDARD;
        
        security_create_user(&account);
    }
    
    // Apply WiFi configuration
    if (strlen(g_setup_config.wifi_ssid) > 0) {
        wifi_connect(g_setup_config.wifi_ssid, g_setup_config.wifi_password);
    }
}
